# frozen_string_literal: true

describe OperationsController do
  let(:user) { User.create(name: 'Test User', bonus: 500, template: loyalty_template) }
  let(:loyalty_template) { Template.create(name: 'Silver', discount: 10, cashback: 5) }
  let(:product1) { Product.create(name: 'Product A', type: 'discount', value: 10) }
  let(:product2) { Product.create(name: 'Product B', type: 'increased_cashback', value: 7) }
  let(:noloyalty_product) { Product.create(name: 'Product C', type: 'noloyalty', value: nil) }

  let(:valid_positions) do
    [
      { id: product1.id, price: 100, quantity: 2 },
      { id: product2.id, price: 50, quantity: 1 },
      { id: noloyalty_product.id, price: 50, quantity: 1 }
    ]
  end

  let(:positions_with_noloyalty) do
    [
      { id: product1.id, price: 100, quantity: 2 },
      { id: noloyalty_product.id, price: 150, quantity: 1 }
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

        expect(response_data[:status]).to eq(200)
        expect(response_data[:operation_id]).not_to be_nil
        expect(response_data[:user][:id]).to eq(user.id)
        expect(response_data[:discount][:summ]).to be > 0 # Проверяем, что скидка рассчитана
        expect(response_data[:cashback][:will_add]).to be > 0 # Проверяем, что кэшбэк начислен

        discount_item = response_data[:positions].find { |pos| pos[:id] == product1.id }
        expect(discount_item[:type]).to eq('discount')
        expect(discount_item[:type_desc]).to eq('Дополнительная скидка 10%')

        # Проверяем описание для кэшбэка
        cashback_item = response_data[:positions].find { |pos| pos[:id] == product2.id }
        expect(cashback_item[:type]).to eq('increased_cashback')
        expect(cashback_item[:type_desc]).to eq('Дополнительный кэшбек 7%')

        # Проверяем описание для noloyalty
        noloyalty_item = response_data[:positions].find { |pos| pos[:id] == noloyalty_product.id }
        expect(noloyalty_item[:type]).to eq('noloyalty')
        expect(noloyalty_item[:type_desc]).to eq('Не участвует в системе лояльности')
      end
    end

    context 'when the positions array includes noloyalty products' do
      it 'ignores loyalty bonuses for noloyalty products' do
        post '/operation', {
          user_id: user.id,
          positions: positions_with_noloyalty
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)

        response_data = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_data[:status]).to eq(200)
        expect(response_data[:positions]).not_to be_empty
        noloyalty_item = response_data[:positions].find { |pos| pos[:type] == 'noloyalty' }
        expect(noloyalty_item[:discount_percent]).to eq(0)
        expect(noloyalty_item[:discount_summ]).to eq(0)
      end
    end

    context 'when the user is not found' do
      it 'returns a 422 status with an error message' do
        post '/operation', {
          user_id: -1,
          positions: valid_positions
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)

        response_data = JSON.parse(last_response.body, symbolize_names: true)
        expect(response_data[:errors]).to include('User with ID -1 not found')
      end
    end

    context 'when the positions parameter is missing' do
      it 'returns a 422 status with an error message' do
        post '/operation', {
          user_id: user.id
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)

        response_data = JSON.parse(last_response.body, symbolize_names: true)
        expect(response_data[:errors]).to include('Positions are required and should be an array')
      end
    end

    context 'when a product in the positions array does not exist' do
      it 'returns a valid response but marks the product as unavailable' do
        post '/operation', {
          user_id: user.id,
          positions: [
            { id: 999, price: 100, quantity: 2 } # Несуществующий продукт
          ]
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)

        response_data = JSON.parse(last_response.body, symbolize_names: true)

        unavailable_product = response_data[:positions].find { |pos| pos[:id] == 999 }
        expect(unavailable_product[:type_desc]).to eq('Product not found')
        expect(unavailable_product[:discount_percent]).to eq(0.0)
        expect(unavailable_product[:discount_summ]).to eq(0.0)
      end
    end

    context 'when JSON payload is invalid' do
      it 'returns a 400 status with an error message' do
        post '/operation', '{ invalid json }', { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)

        response_data = JSON.parse(last_response.body, symbolize_names: true)
        expect(response_data[:error]).to include('Invalid JSON format in request:')
      end
    end

    context 'when positions array is empty' do
      it 'returns a 422 status with an error message' do
        post '/operation', {
          user_id: user.id,
          positions: []
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)

        response_data = JSON.parse(last_response.body, symbolize_names: true)

        expect(response_data[:errors]).to include('Positions are required and should be an array')
      end
    end
  end
end
