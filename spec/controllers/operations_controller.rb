# frozen_string_literal: true

describe OperationsController do
  let(:user) { User.create(name: 'Test User', bonus: 500, template: loyalty_template) }
  let(:loyalty_template) { Template.create(name: 'Silver', discount: 10, cashback: 5) }
  let(:product1) { Product.create(name: 'Product A', type: 'discount', value: 10) }
  let(:product2) { Product.create(name: 'Product B', type: 'increased_cashback', value: 7) }

  let(:valid_positions) do
    [
      { id: product1.id, price: 100, quantity: 2 },
      { id: product2.id, price: 50, quantity: 1 }
    ]
  end

  describe 'POST /operation' do
    context 'when the data is valid' do
      it 'returns a successful response with data' do
        post '/operation', {
          user_id: user.id,
          positions: valid_positions
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        response_data = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_data[:status]).to eq('success')
        expect(response_data[:operation_id]).not_to be_nil
        expect(response_data[:user][:id]).to eq(user.id)
      end
    end

    context 'when the user is not found' do
      it 'returns an error message' do
        post '/operation', {
          user_id: -1,
          positions: valid_positions
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_data = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_data[:errors]).to include('User with ID -1 not found')
      end
    end

    context 'when JSON is invalid' do
      it 'returns an error message' do
        post '/operation', '{ invalid json }', { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)
        response_data = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_data[:error]).to include('Invalid JSON format in request:')
      end
    end

    context 'when positions parameter is missing' do
      it 'returns an error message' do
        post '/operation', {
          user_id: user.id
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_data = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_data[:errors]).to include('Positions are required and should be an array')
      end
    end
  end
end
