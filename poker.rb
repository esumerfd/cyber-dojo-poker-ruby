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

    def valid_suit(suit)
      @@suites.include?(suit) || suit == :joker
    end

    def valid_value(value)
      @@values.include?(value) || value == :joker
    end

    def next_value(value)
      return :joker if value == :joker

      position = @@values.index(value)
      raise "Invalid value #{value}" if position == nil

      position + 1 < @@values.size ? @@values[position + 1] : nil
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

  def select_straight_starting_at(card_or_code)
    cards = []
    cards << card_or_code if card_or_code.kind_of?(Card)
    cards << Card.from_code(card_or_code) if card_or_code.kind_of?(String)

    4.times { cards << cards[-1].next_card }

    cards
  end

  def to_s
    @cards.join(",")
  end
end

class Hand
  attr_accessor :cards

  def initialize(cards)
    @cards = cards if cards.kind_of?(Array)
    @cards = from_code(cards) if cards.kind_of?(String)
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

  private

  def from_code(card_codes)
    cards = []
    card_codes.scan(/[23456789JQKA][CHSD]/).each do |card_code|
      cards << Card.from_code(card_code)
    end
    cards
  end

  def straight_flush?
    cards = @cards.sort
    card_values = cards.collect(&:value)
    deck_values = Deck.new.select_straight_starting_at(@cards.first).collect(&:value)

    card_values == deck_values
  end
end

class Card
  attr_accessor :suit
  attr_accessor :value

  class << self
    def from_code(card_code)
      value_code = card_code[0]
      suit_code = card_code[1]

      value = value_code.to_sym
      suit = suit_code.to_sym

      Card.new(suit, value)
    end

    def joker
      Card.new(:joker, :joker)
    end
  end

  def initialize(suit, value)
    raise "Invalid card suit: #{suit}" unless Deck.valid_suit(suit)
    raise "Invalid card value: #{value}" unless Deck.valid_value(value)

    @suit = suit
    @value = value
  end

  def ==(other)
    nil != other && @suit == other.suit && @value == other.value
  end

  def <=>(other)
    delta = 0
    delta = 1 if value > other.value
    delta = -1 if value < other.value
    delta
  end

  def next_card
    next_value = Deck.next_value(value)
    next_value.nil? ? Card.joker :  Card.new(@suit, next_value)
  end

  def to_s
    "#{value}#{suit}"
  end
end

