# frozen_string_literal: true

module AuthHelper
  def auth_headers(user)
    {
      Authorization: "Bearer #{token(user).token}",
      Accept: "application/json",
      'Content-Type': "application/json"
    }
  end

  def token(user)
    @_token = {} unless defined? @_token
    return @_token[user] if @_token.key?(user)

    @_token[user] = Doorkeeper::AccessToken.create!(resource_owner_id: user.id)
  end

  def graphql_request(query:, variables: {}, headers: {}, user: create(:user))
    post(
      "/api/v1/graphql",
      params: { query: query, variables: variables }.to_json,
      headers: headers.merge(auth_headers(user))
    )
  end
end
