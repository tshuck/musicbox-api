require 'rails_helper'

RSpec.describe RoomPlaylist do
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:user_3) { create(:user) }
  let(:room) { create(:room, user_rotation: [user_1.id, user_2.id, user_3.id]) }

  describe "#waiting" do
    it "should the whole room queue" do
      record1 = create(:room_playlist_record, room: room, user: user_1, order: 7, play_state: "played")
      record2 = create(:room_playlist_record, room: room, user: user_2, order: 1, play_state: "played")
      room.update!(current_record: record2)

      record3 = create(:room_playlist_record, room: room, user: user_3, order: 19, play_state: "waiting")
      record4 = create(:room_playlist_record, room: room, user: user_1, order: 8, play_state: "waiting")
      record5 = create(:room_playlist_record, room: room, user: user_2, order: 2, play_state: "waiting")
      record6 = create(:room_playlist_record, room: room, user: user_3, order: 20, play_state: "waiting")

      playlist = RoomPlaylist.new(room.id)

      expect(playlist.generate_playlist).to eq([record3, record4, record5, record6])
    end
  end
end
