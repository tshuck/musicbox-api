# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    graphql_name "Query"

    field :message, Types::MessageType, null: false do
      argument :id, ID, required: true
    end

    def message(id:)
      Message.find(id)
    end

    field :messages, [Types::MessageType], null: false do
      argument :from, Types::DateTimeType, required: false
      argument :to, Types::DateTimeType, required: false
    end

    def messages(from: nil, to: nil) # rubocop:disable Metrics/AbcSize
      return [] if current_user.active_room.blank?

      t = Message.arel_table
      messages = Message.where(room_id: current_user.active_room_id)
      messages = messages.where(t[:created_at].gteq(from)) if from.present?
      messages = messages.where(t[:created_at].lteq(to)) if to.present?

      messages.order(created_at: :asc)
    end

    field :room, Types::RoomType, null: true do
      argument :id, ID, required: true
    end

    def room(id:)
      rooms = Room.where(id: id)
      rooms = rooms.where(team: current_user.teams) if current_user.present?
      rooms.first
    end

    field :rooms, [Types::RoomType], null: true do
    end

    def rooms
      Room.where(team: current_user.active_team)
    end

    field :room_playlist, [Types::RoomPlaylistRecordType], null: true do
      argument :room_id, ID, required: true
    end

    def room_playlist(room_id:)
      RoomPlaylist.new(room_id).generate_playlist
    end

    field :room_playlist_for_user, [Types::RoomPlaylistRecordType], null: true do
      argument :historical, Boolean, required: true
    end

    def room_playlist_for_user(historical:)
      records = current_user.room_playlist_records.where(room_id: current_user.active_room_id)
      return records.played.order(played_at: :desc) if historical

      records.waiting.order(:order)
    end

    field :song, Types::SongType, null: true do
      argument :id, ID, required: true
    end

    def song(id:)
      Song.find(id)
    end

    field :songs, [Types::SongType], null: true do
    end

    def songs
      current_user.songs
    end

    field :user, Types::UserType, null: false do
    end

    def user
      current_user
    end

    private

    def current_user
      context[:current_user]
    end
  end
end
