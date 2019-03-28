# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include JsonHelper

  def query(youtube_id:)
    %(
      mutation {
        createSong(input:{
          youtubeId: "#{youtube_id}"
        }) {
          song {
            id
            description
            durationInSeconds
            name
            youtubeId
          }
          errors
        }
      }
    )
  end

  describe "#create" do
    it "can be created" do
      video = OpenStruct.new(duration: 1500, title: "a title", description: "a description")
      expect(Yt::Video).to receive(:new).with(id: "an-id").and_return(video)
      post('/api/v1/graphql', params: { query: query(youtube_id: "an-id") })
      data = json_body.dig(:data, :createSong)
      id = data.dig(:song, :id)

      song = Song.find(id)
      expect(song.name).to eq('a title')
      expect(song.description).to eq('a description')
      expect(song.duration_in_seconds).to eq(1500)
      expect(data[:errors]).to be_blank
    end

    it "allows find-or-create by youtube_id" do
      song = create(:song, youtube_id: "the-youtube-id")
      expect(Yt::Video).to_not receive(:new)

      expect do
        post('/api/v1/graphql', params: { query: query(youtube_id: "the-youtube-id") })
        data = json_body.dig(:data, :createSong)
        id = data.dig(:song, :id)

        expect(song.id).to eq(id)
        expect(data[:errors]).to be_blank
      end.to_not change(Song, :count)
    end
  end

  context "when missing required attributes" do
    it "fails to persist when youtube_id is not specified" do
      expect(Yt::Video).to_not receive(:new)
      expect do
        post('/api/v1/graphql', params: { query: query(youtube_id: nil) })
        data = json_body.dig(:data, :createSong)

        expect(data[:song]).to be_nil
        expect(data[:errors]).to match_array([include("Youtube can't be blank")])
      end.to_not change(Song, :count)
    end
  end
end
