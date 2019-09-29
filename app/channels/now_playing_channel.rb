# frozen_string_literal: true

class NowPlayingChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    stream_for room
  end
end
