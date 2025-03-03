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

  describe 'POST /confirm' do
    let(:operation) do
      Operation.create(
        user_id: user.id,
        cashback: 500.0,
        cashback_percent: 5.0,
        discount: 1500.0,
        discount_percent: 15.0,
        write_off: 0,
        check_summ: 10000.0,
        done: false,
        allowed_write_off: 5000.0
      )
    end

    context 'when the confirmation is valid' do
      let(:valid_params) do
        {
          user: {
            id: user.id,
            template_id: user.template_id,
            name: user.name,
            bonus: user.bonus.to_f
          },
          operation_id: operation.id,
          write_off: 500
        }
      end

      it 'returns a successful response with data' do
        post '/confirm', valid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        response_body = JSON.parse(last_response.body)
        expect(response_body['message']).to eq('Operation confirmed successfully')
        expect(response_body['operation']['write_off']).to eq(500.0)
      end
    end

    context 'when the user in request is invalid' do
      let(:invalid_user_params) do
        {
          user: {
            id: 999,
            template_id: 1,
            name: 'Неизвестный пользователь',
            bonus: '5000'
          },
          operation_id: operation.id,
          write_off: 150
        }
      end

      it 'returns a 422 status with error message' do
        post '/confirm', invalid_user_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_body = JSON.parse(last_response.body)
        expect(response_body['errors']).to include('User with ID 999 not found')
      end
    end

    context 'when write-off exceeds allowed limit' do
      let(:invalid_write_off_params) do
        {
          user: {
            id: user.id,
            template_id: user.template_id,
            name: user.name,
            bonus: user.bonus.to_s
          },
          operation_id: operation.id,
          write_off: 6000.0
        }
      end

      it 'returns a 422 status with error message' do
        post '/confirm', invalid_write_off_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_body = JSON.parse(last_response.body)
        expect(response_body['errors']).to include('Write-off exceeds allowed limits. Allowed: 5000.0, Attempted: 6000.0')
      end
    end

    context 'when operation does not exist' do
      let(:invalid_operation_params) do
        {
          user: {
            id: user.id,
            template_id: user.template_id,
            name: user.name,
            bonus: user.bonus.to_s
          },
          operation_id: 999,
          write_off: 150
        }
      end

      it 'returns a 422 status with error message' do
        post '/confirm', invalid_operation_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_body = JSON.parse(last_response.body)
        expect(response_body['errors']).to include('Operation with ID 999 not found')
      end
    end

    context 'when user bonus in request does not match database' do
      let(:invalid_bonus_params) do
        {
          user: {
            id: user.id,
            template_id: user.template_id,
            name: user.name,
            bonus: '5000.0'
          },
          operation_id: operation.id,
          write_off: 150
        }
      end

      it 'returns a 422 status with error message' do
        post '/confirm', invalid_bonus_params.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(422)
        response_body = JSON.parse(last_response.body)
        expect(response_body['errors']).to include('User bonus in request does not match database')
      end
    end
  end
end
