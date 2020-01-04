# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_song, mutation: Mutations::CreateSong

    field :delete_room_playlist_record, mutation: Mutations::DeleteRoomPlaylistRecord
    field :delete_user_library_record, mutation: Mutations::DeleteUserLibraryRecord

    field :invitation_accept, mutation: Mutations::InvitationAccept
    field :invitation_create, mutation: Mutations::InvitationCreate

    field :room_activate, mutation: Mutations::RoomActivate

    field :team_activate, mutation: Mutations::TeamActivate

    field :order_room_playlist_records, mutation: Mutations::OrderRoomPlaylistRecords
  end
end
