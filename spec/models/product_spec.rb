# frozen_string_literal: true

describe Product do
  context 'validations' do
    context 'when valid product' do
      let(:product) { Product.new(name: 'Test Product') }

      it 'is valid' do
        expect(product.valid?).to be true
      end
    end

    context 'when invalid product' do
      let(:product) { Product.new }

      it 'is invalid' do
        expect(product.valid?).to be false
      end

      it 'returns a message' do
        product.valid?
        expect(product.errors[:name]).to include('is not present')
      end
    end
  end

  context 'modifiers' do
    let(:product1) { Product.new(name: 'Test Product', type: 'discount', value: '10') }
    let(:product2) { Product.new(name: 'Test Product', type: 'increased_cashback', value: '5') }
    let(:product3) { Product.new(name: 'Test Product', type: 'noloyalty', value: nil) }

    it 'accepts various product modifiers' do
      expect(product1.valid?).to be true
      expect(product2.valid?).to be true
      expect(product3.valid?).to be true
    end
  end
end
