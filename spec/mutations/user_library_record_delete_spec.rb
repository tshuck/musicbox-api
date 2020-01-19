# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Library Record Delete", type: :request do
  include AuthHelper
  include JsonHelper

  def query(id:)
    %(
      mutation {
        userLibraryRecordDelete(input:{
          id: "#{id}"
        }) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe "success" do
    it "deletes a room playlist record belonging to the user" do
      record = create(:user_library_record, user: current_user)

      graphql_request(
        query: query(id: record.id),
        user: current_user
      )
      data = json_body.dig(:data, :userLibraryRecordDelete)

      expect(data[:errors]).to be_empty
      expect(UserLibraryRecord.find_by(id: record.id)).not_to be_present
    end
  end

  describe "error" do
    it "does not delete a playlist record belonging to another user" do
      record = create(:user_library_record, user: create(:user))

      graphql_request(
        query: query(id: record.id),
        user: current_user
      )
      data = json_body.dig(:data, :userLibraryRecordDelete)

      expect(data[:errors]).not_to be_empty
      expect(UserLibraryRecord.find_by(id: record.id)).to be_present
    end
  end
end
