# frozen_string_literal: true

module Mutations
  class RoomActivate < Mutations::BaseMutation
    argument :room_id, ID, required: true

    field :room, Types::RoomType, null: true
    field :errors, [String], null: true

    def resolve(room_id:)
      room = Room.find_by(id: room_id, team: context[:current_user].teams)
      if room.blank?
        return {
          room: nil,
          errors: ["Room #{room_id} does not exist"]
        }
      end

      previous_room_id = current_user.active_room_id
      current_user.update!(active_room_id: room_id)

      BroadcastUsersWorker.perform_async(previous_room_id) if previous_room_id.present?
      BroadcastUsersWorker.perform_async(room_id)

      {
        room: room,
        errors: []
      }
    end
  end
end
