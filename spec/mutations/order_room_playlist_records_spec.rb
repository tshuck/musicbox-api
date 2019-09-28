# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create Song", type: :request do
  include AuthHelper
  include JsonHelper

  def query(room_id, records)
    input = records.map do |record|
      str = "{ "
      str += "songId: \"#{record[:song_id]}\""
      str += ", roomPlaylistRecordId: \"#{record[:room_playlist_record_id]}\""
      str += " }"
    end

    %(
      mutation {
        orderRoomPlaylistRecords(input:{
          roomId: "#{room_id}",
          orderedRecords: [#{input.join(",")}]
        }) {
          errors
        }
      }
    )
  end

  let(:room) { create(:room) }

  describe "song ordering" do
    it "reorders existing songs" do
      record1 = create(:room_playlist_record, room: room, order: 0, user: current_user)
      record2 = create(:room_playlist_record, room: room, order: 1, user: current_user)

      records = [
        { song_id: record2.song_id, room_playlist_record_id: record2.id},
        { song_id: record1.song_id, room_playlist_record_id: record1.id}
      ]
      authed_post('/api/v1/graphql', query: query(room.id, records))

      expect(record1.reload.order).to eq(1)
      expect(record2.reload.order).to eq(0)
    end

    it "places new songs in order" do
      record = create(:room_playlist_record, room: room, order: 0, user: current_user)
      song1 = create(:song)
      song2 = create(:song)

      records = [
        { song_id: song1.id },
        { song_id: record.song_id, room_playlist_record_id: record.id },
        { song_id: song2.id }
      ]
      authed_post('/api/v1/graphql', query: query(room.id, records))

      new_record_1 = RoomPlaylistRecord.find_by(user: current_user, song_id: song1.id, room: room)
      new_record_2 = RoomPlaylistRecord.find_by(user: current_user, song_id: song2.id, room: room)
      expect(new_record_1.order).to eq(0)
      expect(record.reload.order).to eq(1)
      expect(new_record_2.order).to eq(2)
    end
  end

  describe "user rotation" do
    let(:song) { create(:song) }

    it "places the user in the song rotation when the rotation is empty" do
      room.update!(user_rotation: [])

      records = [{ song_id: song.id }]
      authed_post('/api/v1/graphql', query: query(room.id, records))

      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(0)

      expect(room.reload.user_rotation).to eq([current_user.id])
    end

    it "places the user at the end of an existing song rotation" do
      existing_user_id = SecureRandom.uuid
      room.update!(user_rotation: [existing_user_id])

      records = [{ song_id: song.id }]
      authed_post('/api/v1/graphql', query: query(room.id, records))

      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(0)

      expect(room.reload.user_rotation).to eq([existing_user_id, current_user.id])
    end

    it "does not re-add the user if they are already in the song rotation" do
      existing_user_id = SecureRandom.uuid
      room.update!(user_rotation: [current_user.id, existing_user_id])

      records = [{ song_id: song.id }]
      authed_post('/api/v1/graphql', query: query(room.id, records))

      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(0)

      expect(room.reload.user_rotation).to eq([current_user.id, existing_user_id])
    end
  end

  describe "errors" do
    it "ignores songs that can not be ordered" do
      own_record = create(:room_playlist_record, room: room, order: 0, user: current_user)
      song = create(:song)
      user = create(:user)
      other_record = create(:room_playlist_record, room: room, order: 0, user: user)
      nonexistant_song_id = SecureRandom.uuid
      records = [
        { song_id: nonexistant_song_id },
        { song_id: own_record.song_id, room_playlist_record_id: own_record.id },
        { song_id: other_record.song_id, room_playlist_record_id: other_record.id },
        { song_id: song.id }
      ]
      authed_post('/api/v1/graphql', query: query(room.id, records))

      data = json_body.dig(:data, :orderRoomPlaylistRecords)
      expect(data[:errors].size).to eq(2)
      expect(data[:errors]).to match_array([include(nonexistant_song_id), include(other_record.id)])

      expect(own_record.reload.order).to eq(0)
      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(1)
    end
  end
end