# frozen_string_literal: true

describe Operation do
  let(:template) { Template.create(name: 'Silver', discount: 10, cashback: 5) }
  let(:user) do
    User.create(
      name: 'Test User',
      bonus: 100.0,
      template: template
    )
  end

  context 'validations' do
    subject { operation.valid? }

    before { subject }

    context 'when valid operation' do
      let(:operation) do
        Operation.new(
          user: user,
          cashback: 10.0,
          cashback_percent: 5.0,
          discount: 15.0,
          discount_percent: 10.0,
          check_summ: 100.0,
          write_off: 5.0,
          allowed_write_off: 50.0,
          done: true
        )
      end

      it 'is valid with all fields' do
        expect(subject).to be true
      end
    end

    context 'when invalid operation' do
      let(:operation) { Operation.new }

      it 'is invalid' do
        expect(subject).to be false
      end

      it 'returns a messages' do
        expect(operation.errors[:user_id]).to include('is not present')
        expect(operation.errors[:cashback]).to include('is not present', 'is not a number')
        expect(operation.errors[:cashback_percent]).to include('is not present', 'is not a number')
        expect(operation.errors[:discount]).to include('is not present', 'is not a number')
        expect(operation.errors[:discount_percent]).to include('is not present', 'is not a number')
        expect(operation.errors[:check_summ]).to include('is not present', 'is not a number')
        expect(operation.errors[:write_off]).to include('is not a number')
        expect(operation.errors[:allowed_write_off]).to include('is not a number')
        expect(operation.errors[:done]).to include('is not in range or set: [true, false]')
      end
    end
  end
end
