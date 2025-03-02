# frozen_string_literal: true

describe CalculateDiscountsCommand do
  let(:user) { User.create(name: 'Test User', bonus: 500, template: loyalty_template) }
  let(:loyalty_template) { Template.create(name: 'Silver', discount: 10, cashback: 5) }
  let(:product1) { Product.create(name: 'Product A', type: 'discount', value: 10) }
  let(:product2) { Product.create(name: 'Product B', type: 'increased_cashback', value: 7) }
  let(:product3) { Product.create(name: 'Product C', type: 'noloyalty') }

  let(:valid_positions) do
    [
      { id: product1.id, price: 100, quantity: 2 },
      { id: product2.id, price: 50, quantity: 1 }
    ]
  end

  describe '#call' do
    context 'when the data is valid' do
      it 'calculates and saves the operation successfully' do
        command = described_class.call(user_id: user.id, positions: valid_positions)

        # binding.pry

        expect(command).to be_ok
        expect(command.data_summary[:status]).to eq('success')
        expect(command.data_summary[:operation_id]).not_to be_nil
        expect(command.data_summary[:total_sum]).to be > 0
        expect(command.data_summary[:bonuses][:cashback_value]).to be > 0
        expect(command.data_summary[:discounts][:total_value]).to be > 0
      end
    end

    context 'when the user is not found' do
      it 'returns an error' do
        command = described_class.call(user_id: -1, positions: valid_positions)

        expect(command).to be_error
        expect(command.errors).to include('User with ID -1 not found')
      end
    end

    context 'when the products are not found' do
      it 'returns an error' do
        invalid_positions = [
          { id: -100, price: 100, quantity: 1 }
        ]
        command = described_class.call(user_id: user.id, positions: invalid_positions)

        expect(command).to be_error
        expect(command.errors).to include('Each position should have ID, prices and quantity of a lot of zero')
      end
    end

    context 'when the data is invalid' do
      it 'returns an error if user_id is missing' do
        command = described_class.call(user_id: nil, positions: valid_positions)

        expect(command).to be_error
        expect(command.errors).to include('User ID is required')
      end

      it 'returns an error if positions are missing' do
        command = described_class.call(user_id: user.id, positions: nil)

        expect(command).to be_error
        expect(command.errors).to include('Positions are required and should be an array')
      end

      it 'returns an error if a position has invalid data' do
        invalid_positions = [
          { id: nil, price: 100, quantity: 1 }
        ]
        command = described_class.call(user_id: user.id, positions: invalid_positions)

        expect(command).to be_error
        expect(command.errors).to include('Each position must have id, price, and quantity')
      end
    end

    context 'when the operation cannot be saved' do
      it 'returns a saving error' do
        allow(Operation).to receive(:create).and_raise(StandardError, 'Database write failed')

        command = described_class.call(user_id: user.id, positions: valid_positions)

        expect(command).to be_error
        expect(command.errors).to include('Error while saving operation: Database write failed')
      end
    end
  end
end
