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

  def play
    player1 = deal
    player2 = deal

    puts "Player 1: #{player1}"
    puts "Player 2: #{player2}"
    puts "Winner: #{player1.highest(player2)}"
  end

  def deal
    Hand.new(@deck.cards.sample(5))
  end

  def rank(black, white)
    black.highest(white)
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
    @cards.join(" ")
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

  def <=>(other)
    self.send(:rank) <=> other.send(:rank)
  end

  private

  # 0 nothing
  # 1 high card
  # 2 Pair
  # 3 Two pair
  # 4 Three of a kind
  # 5 Straight
  # 6 Flush
  # 7 Full house
  # 8 Four of a kind
  # 9 Straight flush
  RANKERS = [
    { name: "Straight Flush",  ranker: lambda { |hand| hand.send(:straight_flush) } },
    { name: "Four of a Kind",  ranker: lambda { |hand| hand.send(:four_of_a_kind) } },
    { name: "Full House",      ranker: lambda { |hand| hand.send(:full_house) } },
    { name: "Flush",           ranker: lambda { |hand| hand.send(:flush) } },
    { name: "Straight",        ranker: lambda { |hand| hand.send(:straight) } },
    { name: "Three of a Kind", ranker: lambda { |hand| hand.send(:three_of_a_kind) } },
    { name: "Two Pair",        ranker: lambda { |hand| hand.send(:two_pair) } },
    { name: "Pair",            ranker: lambda { |hand| hand.send(:pair) } },
    { name: "High Card",       ranker: lambda { |hand| hand.send(:high_card) } },
  ]

  def rank
    rank_code = ""

    RANKERS.each_with_index { |ranker_data, index|
      rank_code = ranker_data[:ranker].call(self)
      break if rank_code
    }

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

  # Straight flush: 5 cards of the same suit with consecutive
  # values. Ranked by the highest card in the hand.
  def straight_flush
    rank_code = nil

    card_values = @cards.collect(&:value).sort
    deck_values = Deck.new.select_straight_starting_at(@cards.first).collect(&:value)

    different_suites = @cards.collect(&:suit)
    
    if card_values == deck_values && different_suites.uniq.size == 1
      rank_code = "09|#{sorted_code}"
    end

    rank_code
  end

  # Four of a kind: 4 cards with the same value. Ranked by the
  # value of the 4 cards.
  def four_of_a_kind
    rank_code = nil

    values = @cards.collect(&:value)

    uniq_values = values.uniq
    first_value = uniq_values.first
    second_value = uniq_values[1]

    if values.count(first_value) == 4
      rank_code = "08|#{format_code([first_value] * 4, second_value)}"
    elsif  values.count(second_value) == 4
      rank_code = "08|#{format_code([second_value] * 4, first_value)}"
    end

    rank_code
  end

  # Full House: 3 cards of the same value, with the remaining 2
  # cards forming a pair. Ranked by the value of the 3 cards.
  def full_house
    rank_code = nil

    values = @cards.collect(&:value)

    uniq_values = values.uniq
    first_value = uniq_values.first
    second_value = uniq_values[1]

    if values.count(first_value) == 3 && values.count(second_value) == 2
      rank_code = "07|#{format_code([first_value] * 3, [second_value] * 2)}"
    elsif values.count(first_value) == 2 && values.count(second_value) == 3
      rank_code = "07|#{format_code([second_value] * 3, [first_value] * 2)}"
    end

    rank_code
  end

  # Flush: Hand contains 5 cards of the same suit. Hands which 
  # are both flushes are ranked using the rules for High Card.
  def flush
    rank_code = nil

    suites = @cards.collect(&:suit)

    if suites.uniq.size == 1 && !straight_flush
      rank_code = "06|#{sorted_code}"
    end

    rank_code
  end

  # Straight: Hand contains 5 cards with consecutive values. 
  # Hands which both contain a straight are ranked by their 
  # highest card.
  def straight
    rank_code = nil

    card_values = @cards.collect(&:value).sort
    deck_values = Deck.new.select_straight_starting_at(@cards.first).collect(&:value)

    if card_values == deck_values
      rank_code = "05|#{sorted_code}"
    end

    rank_code
  end

  # Three of a Kind: Three of the cards in the hand have the 
  # same value. Hands which both contain three of a kind are 
  # ranked by the value of the 3 cards.
  def three_of_a_kind
    rank_code = nil

    values = @cards.collect(&:value)

    counts = {}
    values.inject(counts) { |count, value| 
      count[value] = count[value] ? count[value] + 1 : 1 
      count
    }

    number_pairs = counts.values.find_all { |count| count == 3 }
    if number_pairs.size == 1
      sorted_values = counts.keys.sort { |value_a, value_b| 
        value_a_rank = sprintf "%02d|%02d", counts[value_a], value_a.weight 
        value_b_rank = sprintf "%02d|%02d", counts[value_b], value_b.weight

        value_b_rank <=> value_a_rank
      }

      rank_code = "04|"
      sorted_values.each { |value|
        rank_code << format_code([value] * counts[value])
      }
    end


    rank_code
  end

  # Two Pairs: The hand contains 2 different pairs. Hands 
  # which both contain 2 pairs are ranked by the value of 
  # their highest pair. Hands with the same highest pair 
  # are ranked by the value of their other pair. If these 
  # values are the same the hands are ranked by the value 
  # of the remaining card.
  def two_pair
    rank_code = nil

    values = @cards.collect(&:value)

    counts = {}
    values.inject(counts) { |count, value| 
      count[value] = count[value] ? count[value] + 1 : 1 
      count
    }

    number_pairs = counts.values.find_all { |count| count == 2 }
    if number_pairs.size == 2
      sorted_values = counts.keys.sort { |value_a, value_b| 
        value_a_rank = sprintf "%02d|%02d", counts[value_a], value_a.weight 
        value_b_rank = sprintf "%02d|%02d", counts[value_b], value_b.weight

        value_b_rank <=> value_a_rank
      }

      rank_code = "03|"
      sorted_values.each { |value|
        rank_code << format_code([value] * counts[value])
      }
    end

    rank_code
  end

  # Pair: 2 of the 5 cards in the hand have the same value. 
  # Hands which both contain a pair are ranked by the value of
  # the cards forming the pair. If these values are the same, 
  # the hands are ranked by the values of the cards not 
  # forming the pair, in decreasing order.
  def pair
    rank_code = nil

    return rank_code if full_house
    
    values = @cards.collect(&:value)

    counts = {}
    values.inject(counts) { |count, value| 
      count[value] = count[value] ? count[value] + 1 : 1 
      count
    }

    number_pairs = counts.values.find_all { |count| count == 2 }
    if number_pairs.size == 1
      sorted_values = counts.keys.sort { |value_a, value_b| 
        value_a_rank = sprintf "%02d|%02d", counts[value_a], value_a.weight 
        value_b_rank = sprintf "%02d|%02d", counts[value_b], value_b.weight

        value_b_rank <=> value_a_rank
      }

      rank_code = "02|"
      sorted_values.each { |value|
        rank_code << format_code([value] * counts[value])
      }
    end


    rank_code
  end

  # High Card: Hands which do not fit any higher category are
  # ranked by the value of their highest card. If the highest
  # cards have the same value, the hands are ranked by the next
  # highest, and so on.
  def high_card
    "01|#{sorted_code}"
  end

  def sorted_code
    format_code( @cards.collect(&:value).sort { |a, b| b <=> a } )
  end

  def format_code(*values)
    code = ""

    values = values.flatten
    values.collect do |value|
      code << "%02d" % value.weight.to_s
    end

    code
  end

  def to_s
    @cards.join(" ")
  end
end

class Card
  attr_accessor :suit
  attr_accessor :value

  class << self
    def from_code(card_code)
      sorted_code = card_code[0]
      suit_code = card_code[1]

      value = sorted_code.to_sym
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
    value <=> other.value
  end

  def next_card
    next_value = Value.next(value)
    next_value.nil? ? Card.joker :  Card.new(@suit, next_value)
  end

  def to_s
    "#{value}#{suit}"
  end
end

if ARGV.size == 1 && ARGV[0] == "-play"
  Poker.new.play
end
