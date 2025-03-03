# frozen_string_literal: true

describe User do
  context 'validations' do
    subject { user.valid? }

    let(:template) { Template.create(name: 'Silver', discount: 10, cashback: 5) }

    before { subject }

    context 'when valid user' do
      let(:user) { User.new(name: 'Test User', template: template, bonus: 100.0) }

      it 'is valid' do
        expect(subject).to be true
      end
    end

    context 'when invalid user' do
      context 'without name' do
        let(:user) { User.new(template: template) }

        it 'is invalid' do
          expect(subject).to be false
        end

        it 'returns a message' do
          expect(user.errors[:name]).to include('is not present')
        end
      end

      context 'without template' do
        let(:user) { User.new(name: 'Test User') }

        it 'is invalid' do
          expect(subject).to be false
        end

        it 'returns a message' do
          expect(user.errors[:template_id]).to include('is not present')
        end
      end

      context 'when non-numeric bonus' do
        let(:user) { User.new(name: 'Test User', template: template, bonus: 'wrong_value') }

        it 'is invalid' do
          expect(subject).to be false
        end

        it 'returns a message' do
          expect(user.errors[:bonus]).to include('is not a number')
        end
      end
    end
  end

  context 'associations' do
    let(:template) { Template.create(name: 'Silver', discount: 10, cashback: 5) }
    let(:user) { User.create(name: 'Test User', template: template, bonus: 100.0) }
    let(:operation1) do
      Operation.create(
        user: user,
        cashback: 10.0,
        cashback_percent: 5.0,
        discount: 15.0,
        discount_percent: 10.0,
        check_summ: 100.0,
        write_off: 5.0,
        allowed_write_off: 10.0,
        done: false
      )
    end
    let(:operation2) do
      Operation.create(
        user: user,
        cashback: 20.0,
        cashback_percent: 6.0,
        discount: 10.0,
        discount_percent: 5.0,
        check_summ: 200.0,
        write_off: 3.0,
        allowed_write_off: 15.0,
        done: true
      )
    end

    it 'belongs to a template' do
      expect(user.template).to eq(template)
    end

    it 'has many operations' do
      expect(user.operations).to contain_exactly(operation1, operation2)
    end
  end
end
