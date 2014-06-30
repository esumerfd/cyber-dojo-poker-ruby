require 'rspec'
require './poker'

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

    context "cards" do
      it "selects straight from code" do
        expect( Deck.new.select_straight_starting_at("4C") ).to eq(
          [
            Card.new(:C, :"4"),
            Card.new(:C, :"5"),
            Card.new(:C, :"6"),
            Card.new(:C, :"7"),
            Card.new(:C, :"8"),
          ]
        )
      end
      
      it "selects straight from card" do
        expect( Deck.new.select_straight_starting_at(Card.new(:C, :"4")) ).to eq(
          [
            Card.new(:C, :"4"),
            Card.new(:C, :"5"),
            Card.new(:C, :"6"),
            Card.new(:C, :"7"),
            Card.new(:C, :"8"),
          ]
        )
      end

      it "selects straight from 9" do
        expect( Deck.new.select_straight_starting_at("9H") ).to eq(
          [
            Card.new(:H, :"9"),
            Card.new(:H, :J),
            Card.new(:H, :Q),
            Card.new(:H, :K),
            Card.new(:H, :A),
          ]
        )
      end

      it "selects straight from end of deck" do
        expect( Deck.new.select_straight_starting_at("AC") ).to eq(
          [
            Card.new(:C, :A),
            Card.joker,
            Card.joker,
            Card.joker,
            Card.joker,
          ]
        )
      end
    end

    context "next value" do

      it "plus one" do
        expect( Deck.next_value(:"2") ).to eq(:"3")
        expect( Deck.next_value(:"9") ).to eq(:J)
        expect( Deck.next_value(:K) ).to eq(:A)
      end

      it "nil at end of list" do
        expect( Deck.next_value(:A) ).to eq(nil)
      end

      it "returns a joker for a joker" do
        expect( Deck.next_value(:joker) ).to eq(:joker)
      end

      it "raises on invalid values" do
        expect { Deck.next_value(:IVNALID_VALUE) }.to raise_error
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
    context "encode rank" do
      it "is straight flish" do
        expect(Hand.new("2C3C4C5C6C").send(:straight_flush?)).to eq(true)

        #expect(Hand.new("2C3C4C5C6C").rank_code).to eq("960000000000000000")
      end

    end
  end

  context Card do

    context "construction" do

      it "with a suit and a vlaue" do
        card = Card.new(:C, :"2")
        expect(card.suit).to eq(:C)
        expect(card.value).to eq(:"2")
      end

      it "with a card_code" do
        card = Card.from_code("3S")
        expect(card.suit).to eq(:S)
        expect(card.value).to eq(:"3")
      end

      it "with invalid card code" do
        expect { Card.from_code("XX") }.to raise_error
      end

    end

    it "compares equal" do
      expect( Card.new(:H, :A) ).to eq( Card.new(:H, :A) )
    end

    it "compares not equal" do
      expect( Card.new(:H, :A) ).not_to eq( Card.new(:C, :A) )
      expect( Card.new(:H, :A) ).not_to eq( Card.new(:H, :J) )
      expect( Card.new(:H, :A) ).not_to eq( nil )
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

    context "next card" do
      it "generates the next card" do
        expect( Card.new(:C, :"2").next_card ).to eq(Card.new(:C, :"3"))
      end

      it "products jokers if there is no next card" do
        expect( Card.new(:C, :A).next_card ).to eq(Card.joker)
      end
    end

    context "sorts cards by value and" do
      it "finds first greater than second" do
        cards = [Card.new(:C, :"3"), Card.new(:C, :"2")]

        cards = cards.sort

        expect(cards[0].value).to eq(:"2")
        expect(cards[1].value).to eq(:"3")
      end

      it "finds second greater than first" do
        cards = [Card.new(:C, :"2"), Card.new(:C, :"3")]

        cards = cards.sort

        expect(cards[0].value).to eq(:"2")
        expect(cards[1].value).to eq(:"3")
      end
      
      it "finds equal values equal" do
        cards = [Card.new(:C, :"3"), Card.new(:C, :"3")]

        cards = cards.sort

        expect(cards[0].value).to eq(:"3")
        expect(cards[1].value).to eq(:"3")
      end

      it "ignores suit" do
        cards = [Card.new(:S, :"3"), Card.new(:C, :"3")]

        cards = cards.sort

        expect(cards[0].value).to eq(:"3")
        expect(cards[1].value).to eq(:"3")
      end
    end
  end
end
