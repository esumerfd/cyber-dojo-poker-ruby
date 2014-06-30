class Value

  attr_reader :value

  def initialize(value)
    @value = value
  end

  def weight
    values = @@values.collect(&:value)
    index = values.index(value)
    index.nil? ? 0 : index + 2
  end

  def ==(other)
    return false if other.nil?
    @value == other.value
  end

  def <(other)
    send(:<=>, other) == -1
  end

  def >(other)
    send(:<=>, other) == 1
  end

  def <=>(other)
    weight <=> other.weight
  end

   def eql?(other)
     @value == other.value
   end
    
   def hash
     @value.hash
   end 

  def to_s
    @value.to_s
  end
end

class Value
  class << self

    def two   
      Value.new(:"2") 
    end
    def three 
      Value.new(:"3") 
    end
    def four 
      Value.new(:"4") 
    end
    def five 
      Value.new(:"5")
    end
    def six 
      Value.new(:"6")
    end
    def seven 
      Value.new(:"7")
    end
    def eight 
      Value.new(:"8")
    end
    def nine 
      Value.new(:"9")
    end
    def jack 
      Value.new(:J)
    end
    def queen 
      Value.new(:Q)
    end
    def king 
      Value.new(:K)
    end
    def ace 
      Value.new(:A)
    end
    def joker
      Value.new(:joker)
    end

    @@values = [
        Value.two,
        Value.three,
        Value.four,
        Value.five,
        Value.six,
        Value.seven,
        Value.eight,
        Value.nine,
        Value.jack,
        Value.queen,
        Value.king,
        Value.ace
    ] 
    def values
      @@values
    end

    def valid(value)
      @@values.include?(value) || value == Value.joker
    end

    def from_code(value)
      Value.new(value)
    end

    def next(value)
      return Value.joker if value == Value.joker

      position = @@values.index(value)
      raise "Invalid value #{value}" if position == nil

      position + 1 < @@values.size ? @@values[position + 1] : nil
    end
  end

end

class Poker
  attr_accessor :deck

  def initialize
    @deck = Deck.new
  end

  def deal
    Hand.new(@deck.cards.sample(5))
  end

  def rank(black, white)
    winner = black.highest(white)
    return winner, winner.high_card if winner
  end
end

class Deck
  @@suites = [:C, :D, :H, :S]

  class << self
    def suites
      @@suites
    end

    def create_cards
      cards = []
      @@suites.each do |suit|
        Value.values.each do |value|
          cards << Card.new(suit, value)
        end
      end
      cards
    end

    def valid_suit(suit)
      @@suites.include?(suit) || suit == :joker
    end

    def valid_value(value)
      Valid.valid(value)
    end

    def next_value(value)
      Value.next(value)
    end
  end

  attr_reader :cards

  def initialize(cards = nil)
    @cards = cards ||= Deck.create_cards
  end

  def full?
    return false unless @cards.size == 48

    missing_card = @@suites.find do |suit|
      Value.values.find do |value|
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

  def highest(other)

    delta = self <=> other

    highest = nil
    highest = self if delta == 1
    highest = other if delta == -1

    highest
  end

  def high_card
    @cards.max { |a,b| a.value <=> b.value }
  end

  def <=>(other)
    delta = 0

    delta = 1 if self.send(:rank) > other.send(:rank)
    delta = -1 if self.send(:rank) < other.send(:rank)

    delta
  end

  private

  def rank
    rank_code = ""

    rank_code << (straight_flush? ? "11" : "00")
    rank_code << (four_of_a_kind? ? "11" : "00")
    rank_code << (full_house? ? "11" : "00")
    rank_code << (flush? ? "11" : "00")
    rank_code << (straight? ? "11" : "00")
    rank_code << (three_of_a_kind? ? "11" : "00")
    rank_code << (two_pair? ? "11" : "00")
    rank_code << (pair? ? "11" : "00")

    puts ">>>> #{File.basename(__FILE__)}:#{__LINE__}, #{rank_code}"

    rank_code
  end

  def from_code(card_codes)
    card_codes = card_codes.tr(" ,", "")

    cards = []
    card_codes.scan(/[23456789JQKA][CHSD]/).each do |card_code|
      cards << Card.from_code(card_code)
    end

    raise "Wrong number of cards #{cards}" if cards.size != 5

    cards
  end

  def straight_flush?
    card_values = @cards.collect(&:value).sort
    deck_values = Deck.new.select_straight_starting_at(@cards.first).collect(&:value)

    different_suites = @cards.collect(&:suit)
    
    card_values == deck_values && different_suites.uniq.size == 1
  end

  def four_of_a_kind?
    values = @cards.collect(&:value)

    uniq_values = values.uniq
    first_value = uniq_values.first
    second_value = uniq_values[1]

    values.count(first_value) == 4 || values.count(second_value) == 4
  end

  def full_house?
    values = @cards.collect(&:value)

    uniq_values = values.uniq
    first_value = uniq_values.first
    second_value = uniq_values[1]

    values.count(first_value) == 3 && values.count(second_value) == 2 ||
    values.count(first_value) == 2 && values.count(second_value) == 3
  end

  def flush?
    suites = @cards.collect(&:suit)
    suites.uniq.size == 1 && !straight_flush?
  end

  def straight?
    card_values = @cards.collect(&:value).sort
    deck_values = Deck.new.select_straight_starting_at(@cards.first).collect(&:value)

    card_values == deck_values
  end

  def three_of_a_kind?
    values = @cards.collect(&:value)

    uniq_values = values.uniq
    first_value = uniq_values.first
    second_value = uniq_values[1]
    third_value = uniq_values[2]

    (values.count(first_value) == 3 || values.count(second_value) == 3 || values.count(third_value) == 3)
  end

  def two_pair?
    values = @cards.collect(&:value)

    uniq_values = values.uniq
    first_value = uniq_values.first
    second_value = uniq_values[1]
    third_value = uniq_values[2]

    values.count(first_value) == 2 && values.count(second_value) == 2 || 
    values.count(first_value) == 2 && values.count(third_value) == 2 ||
    values.count(second_value) == 2 && values.count(third_value) == 2
  end

  def pair?
    values = @cards.collect(&:value)
    values.uniq.size == 4
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

      Card.new(suit, Value.from_code(value))
    end

    def joker
      Card.new(:joker, Value.joker)
    end
  end

  def initialize(suit, value)
    raise "Deprecated passing symbols into card" if value.kind_of?(Symbol)

    raise "Invalid card suit: #{suit}" unless Deck.valid_suit(suit)
    raise "Invalid card value: #{value}" unless Value.valid(value)

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
    next_value = Value.next(value)
    next_value.nil? ? Card.joker :  Card.new(@suit, next_value)
  end

  def to_s
    "#{value}#{suit}"
  end
end


