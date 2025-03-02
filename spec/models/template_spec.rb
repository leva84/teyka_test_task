# frozen_string_literal: true

describe Template do
  context 'validations' do
    subject { template.valid? }

    before { subject }

    context 'when valid template' do
      let(:template) { Template.new(name: 'Bronze', discount: 0, cashback: 10) }

      it 'is valid' do
        expect(subject).to be true
      end
    end

    context 'when invalid template' do
      context 'without name' do
        let(:template) { Template.new(discount: 0, cashback: 10) }

        it 'is invalid' do
          expect(subject).to be false
        end

        it 'returns a message' do
          expect(template.errors[:name]).to include('is not present')
        end
      end

      context 'without discount or cashback' do
        let(:template) { Template.new(name: 'Silver') }

        it 'is invalid' do
          expect(subject).to be false
        end

        it 'returns a messages' do
          expect(template.errors[:discount]).to include('is not present')
          expect(template.errors[:cashback]).to include('is not present')
        end
      end

      context 'when non-integer discount or cashback' do
        let(:template) { Template.new(name: 'Gold', discount: 'ten', cashback: 'five') }

        it 'is invalid' do
          expect(subject).to be false
        end

        it 'is invalid with non-integer discount or cashback' do
          expect(template.errors[:discount]).to include('is not a number')
          expect(template.errors[:cashback]).to include('is not a number')
        end
      end
    end
  end

  context 'associations' do
    let(:template) { Template.create(name: 'Gold', discount: 15, cashback: 0) }
    let(:user1) { User.create(name: 'User 1', bonus: 0, template: template) }
    let(:user2) { User.create(name: 'User 2', bonus: 0, template: template) }

    it 'has many users' do
      expect(template.users).to contain_exactly(user1, user2)
    end
  end
end
