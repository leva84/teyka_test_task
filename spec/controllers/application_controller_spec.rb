# frozen_string_literal: true

describe ApplicationController do
  describe 'GET /' do
    subject { get '/' }

    let(:content_type) { 'application/json' }
    let(:message) { { 'message' => 'Welcome to the API!' } }

    before { subject }

    it 'returns a 200 status code' do
      expect(last_response).to be_ok
    end

    it 'returns a JSON response' do
      expect(last_response.content_type).to eq content_type
    end

    it 'returns a welcome message' do
      expect(JSON.parse(last_response.body)).to eq message
    end
  end
end
