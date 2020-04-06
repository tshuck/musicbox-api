# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Messages Query", type: :request do
  include AuthHelper
  include JsonHelper

  let(:team) { create(:team) }
  let(:room) { create(:room, team: team) }
  let(:star_fighter) { create(:song, name: "Star Fighter", duration_in_seconds: 100) }
  let(:hootsforce) { create(:song, name: "Hootsforce", duration_in_seconds: 100) }
  let(:truman) { create(:user, name: "truman", teams: [team], songs: [star_fighter, hootsforce]) }
  let(:dan) { create(:user, name: "dan", teams: [team], songs: [star_fighter, hootsforce]) }
  let!(:play_future1) do
    create(:room_playlist_record, song: star_fighter, user: truman, room: room, play_state: "waiting", order: 1)
  end
  let!(:play_future2) do
    create(:room_playlist_record, song: hootsforce, user: truman, room: room, play_state: "waiting", order: 2)
  end
  let!(:play_future3) do
    create(:room_playlist_record, song: star_fighter, user: dan, room: room, play_state: "waiting", order: 1)
  end
  let!(:play_future4) do
    create(:room_playlist_record, song: hootsforce, user: dan, room: room, play_state: "waiting", order: 2)
  end

  def query
    %(
      query RoomPlaylist($roomId: ID!) {
        roomPlaylist(roomId: $roomId) {
          id
          song {
            id
            name
          }
          user {
            email
            name
          }
        }
      }
    )
  end

  context "when requesting future playlist" do
    it "returns songs in order" do
      room.update!(user_rotation: [truman.id, dan.id])

      graphql_request(query: query, variables: { roomId: room.id }, user: truman)
      playlist = json_body.dig(:data, :roomPlaylist).map { |r| r[:id] }
      expect(playlist).to eq([play_future1.id, play_future3.id, play_future2.id, play_future4.id])
    end
  end
end
