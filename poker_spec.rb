require 'rspec'

class Poker
  attr_accessor :deck

  def initialize
    @deck = Deck.new
  end

  def deal
    Hand.new(@deck.cards.sample(5))
  end

  def rank(black, white)
    return black.highest(white), Card.new(:H, :A)
  end
end

class Deck
  @@suites = [:C, :D, :H, :S]
  @@values = [:"2", :"3", :"4", :"5", :"6", :"7", :"8", :"9", :J, :Q, :K, :A]

  class << self
    def values
      @@values
    end


    def suites
      @@suites
    end

    def create_cards
      cards = []
      @@suites.each do |suit|
        @@values.each do |value|
          cards << Card.new(suit, value)
        end
      end
      cards
    end
  end

  attr_reader :cards

  def initialize(cards = nil)
    @cards = cards ||= Deck.create_cards
  end

  def full?
    return false unless @cards.size == 48

    missing_card = @@suites.find do |suit|
      @@values.find do |value|
        false == card?(suit, value)
      end
    end

    missing_card.nil?
  end

  def card?(suit, value)
    @cards.find do |card|
      card.suit == suit && card.value == value
    end != nil
  end

  def to_s
    @cards.join(",")
  end
end

class Hand
  attr_accessor :cards

  def initialize(cards)
    @cards = cards if cards.kind_of?(Array)
    @cards = parse(cards) if cards.kind_of?(String)
  end

  def parse(card_codes)
    cards = []
    card_codes.scan(/[23456789JQKA][CHSD]/).each do |card_code|
      value_code = card_code[0]
      suit_code = card_code[1]

      value = value_code.to_sym
      suit = suit_code.to_sym

      cards << Card.new(suit, value)
    end
    cards
  end

  def highest(white)
    # high card
    # Pair
    # Two pair
    # Three of a kind
    # Straight
    # Flush
    # Full house
    # Four of a kind
    # Straight flush
    return white
  end
end

class Card
  attr_accessor :suit
  attr_accessor :value

  def initialize(suit, value)
    raise "Invalid card suit: #{suit}" unless Deck.suites.include?(suit)
    raise "Invalid card value: #{value}" unless Deck.values.include?(value)

    @suit = suit
    @value = value
  end

  def ==(other)
    nil != other && @suit == other.suit && @value == other.value
  end

  def to_s
    "#{value}#{suit}"
  end
end

describe "Poker Game" do
  context Poker do
    it "has a valid deck of cards" do
      expect(Poker.new.deck).not_to eq(nil)
    end

    it "can deal 5 cards" do
      expect( Poker.new.deal ).not_to eq(nil)
      expect( Poker.new.deal ).to be_a_kind_of(Hand)
    end

    it "deals unique cards" do
      hand = Poker.new.deal

      cards = hand.cards

      cards.each do |card|
        expect( cards.count(card) ).to eq(1)
      end
    end

    it "ranks hands" do
      black = Hand.new("2H3D5S9CKD")
      white = Hand.new("2C3H4SBCAH")

      poker = Poker.new

      winner, high_card = poker.rank(black, white)

      expect(winner).to eq(white)
      expect(high_card).to eq(Card.new(:H, :A))
    end
  end

  context Deck do
    it "has suites" do
      expect(Deck.suites).to eq([:C, :D, :H, :S])
    end

    it "has a full deck" do
      expect(Deck.new).to be_full
    end

    it "does not miss any cards" do
      cards = Deck.create_cards
      cards[3].value = :"6"

      deck = Deck.new(cards)

      expect(deck).not_to be_full
    end

    it "doesn't have a full deck if a card is missing" do
      expect(Deck.new([])).not_to be_full
      expect(Deck.new([Card.new(:C, :Q)])).not_to be_full
    end

    Deck.suites.each do |suit|
      Deck.values.each do |value|
        it "has card #{suit} #{value}" do
          expect(Deck.new.card?(suit, value)).to eq(true)
        end
      end
    end
  end

  context Hand do
    it "constructs a hand from a string" do
      hand = Hand.new("2C3S4H5D6C")

      expect(hand.cards[0]).to eq(Card.new(:C, :"2"))
      expect(hand.cards[1]).to eq(Card.new(:S, :"3"))
      expect(hand.cards[2]).to eq(Card.new(:H, :"4"))
      expect(hand.cards[3]).to eq(Card.new(:D, :"5"))
      expect(hand.cards[4]).to eq(Card.new(:C, :"6"))
    end

    it "finds the highest hand" do
      black = Hand.new("2H3D5S9CKD")
      white = Hand.new("2C3H4SBCAH")

      expect( black.highest(white) ).to eq(white)
    end
  end

  context Card do

    it "compares equal" do
      expect( Card.new(:H, :A) ).to eq( Card.new(:H, :A) )
    end

    it "compares not equal" do
      expect( Card.new(:H, :A) ).not_to eq( Card.new(:C, :A) )
      expect( Card.new(:H, :A) ).not_to eq( Card.new(:H, :J) )
      expect( Card.new(:H, :A) ).not_to eq( nil )
    end

    it "can is constructed with a suit and a vlaue" do
      card = Card.new(:C, :"2")
      expect(card.suit).to eq(:C)
      expect(card.value).to eq(:"2")
    end

    Deck.suites.each do |suit|
      Deck.values.each do |value|
        it "can have values #{suit} #{value}"  do
          expect(Card.new(suit, value).value).to eq(value)
        end
      end
    end

    it "can not have invalid suit" do
      expect { Card.new(:INVALID_SUIT, :"2") }.to raise_error
    end

    [:"0", :"1", 2, :invalid_value].each do |value|
      it "can not have value #{value}" do
        expect { Card.new(:C, value) }.to raise_error
      end
    end
  end
end
