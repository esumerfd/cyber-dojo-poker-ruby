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

    context "cyber-dojo example" do

      # Input: Black: 2H 3D 5S 9C KD White: 2C 3H 4S 8C AH
      # Output: White wins - high card: Ace 
      it "one" do
        black = Hand.new("2H 3D 5S 9C KD")
        white = Hand.new("2C 3H 4S 8C AH")

        winner = Poker.new.rank(black, white)

        expect( winner ).to eq(white)
      end

      # Input: Black: 2H 4S 4C 2D 4H White: 2S 8S AS QS 3S
      # Output: Black wins - full house
      it "two" do
        black = Hand.new("2H 4S 4C 2D 4H")
        white = Hand.new("2S 8S AS QS 3S")

        winner = Poker.new.rank(black, white)

        expect( winner ).to eq(black)
      end

      # Input: Black: 2H 3D 5S 9C KD White: 2C 3H 4S 8C KH
      # Output: Black wins - high card: 9
      it "three" do
        black = Hand.new("2H 3D 5S 9C KD")
        white = Hand.new("2C 3H 4S 8C KH")

        winner = Poker.new.rank(black, white)

        expect( winner ).to eq(black)
      end

      # Input: Black: 2H 3D 5S 9C KD White: 2D 3H 5C 9S KH
      # Output: Tie
      it "four" do
        black = Hand.new("2H 3D 5S 9C KD")
        white = Hand.new("2D 3H 5C 9S KH")

        winner = Poker.new.rank(black, white)

        expect( winner ).to eq(nil)
      end
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
      cards[3].value = Value.six

      deck = Deck.new(cards)

      expect(deck).not_to be_full
    end

    it "doesn't have a full deck if a card is missing" do
      expect(Deck.new([])).not_to be_full
      expect(Deck.new([Card.new(:C, Value.queen)])).not_to be_full
    end

    Deck.suites.each do |suit|
      Value.values.each do |value|
        it "has card #{suit} #{value}" do
          expect(Deck.new.card?(suit, value)).to eq(true)
        end
      end
    end

    context "cards" do
      it "selects straight from code" do
        expect( Deck.new.select_straight_starting_at("4C") ).to eq(
          [
            Card.new(:C, Value.four),
            Card.new(:C, Value.five),
            Card.new(:C, Value.six),
            Card.new(:C, Value.seven),
            Card.new(:C, Value.eight),
          ]
        )
      end
      
      it "selects straight from card" do
        expect( Deck.new.select_straight_starting_at(Card.new(:C, Value.four)) ).to eq(
          [
            Card.new(:C, Value.four),
            Card.new(:C, Value.five),
            Card.new(:C, Value.six),
            Card.new(:C, Value.seven),
            Card.new(:C, Value.eight),
          ]
        )
      end

      it "selects straight from 9" do
        expect( Deck.new.select_straight_starting_at("9H") ).to eq(
          [
            Card.new(:H, Value.nine),
            Card.new(:H, Value.jack),
            Card.new(:H, Value.queen),
            Card.new(:H, Value.king),
            Card.new(:H, Value.ace),
          ]
        )
      end

      it "selects straight from end of deck" do
        expect( Deck.new.select_straight_starting_at("AC") ).to eq(
          [
            Card.new(:C, Value.ace),
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
        expect( Deck.next_value(Value.two) ).to eq(Value.three)
        expect( Deck.next_value(Value.nine) ).to eq(Value.jack)
        expect( Deck.next_value(Value.king) ).to eq(Value.ace)
      end

      it "nil at end of list" do
        expect( Deck.next_value(Value.ace) ).to eq(nil)
      end

      it "returns a joker for a joker" do
        expect( Deck.next_value(Value.joker) ).to eq(Value.joker)
      end

      it "raises on invalid values" do
        expect { Deck.next_value(:IVNALID_VALUE) }.to raise_error
      end
    end

    context "to_s" do
      it "formats all cards" do
        expect( Deck.new([Card.new(:H, Value.two), Card.new(:D, Value.ace)]).to_s ).to eq("2H AD")
      end
    end
  end

  context Hand do
    it "constructs a hand from a string" do
      hand = Hand.new("2C3S4H5D6C")

      expect(hand.cards[0]).to eq(Card.new(:C, Value.two))
      expect(hand.cards[1]).to eq(Card.new(:S, Value.three))
      expect(hand.cards[2]).to eq(Card.new(:H, Value.four))
      expect(hand.cards[3]).to eq(Card.new(:D, Value.five))
      expect(hand.cards[4]).to eq(Card.new(:C, Value.six))
    end

    it "raises if the hand is not complete" do
      expect { Hand.new("") }.to raise_error
    end

   
    context "winning hand" do
      context "straight flush" do
        it "is" do
          expect( Hand.new("2C 3C 4C 5C 6C").send(:straight_flush) ).to eq("09|0605040302")
        end
        it "isn't because of number" do
          expect( Hand.new("2C 3C 9C 5C 6C").send(:straight_flush) ).to eq(nil)
        end
        it "isn't because of suit" do
          expect( Hand.new("2C 3C 4S 5C 6C").send(:straight_flush) ).to eq(nil)
        end
      end

      context "four of a kind" do
        it "is" do
          expect( Hand.new("2C 2S 2H 2D 3C").send(:four_of_a_kind) ).to eq("08|0202020203")
        end
        it "isn't" do
          expect( Hand.new("2C 3S 2H 2D 3C").send(:four_of_a_kind) ).to eq(nil)
        end
      end

      context "full house" do
        it "is with high_card" do
          expect( Hand.new("2C 2S 2H 3C 3S").send(:full_house) ).to eq("07|0202020303")
        end
        it "is with low card" do
          expect( Hand.new("JC JS JH 3C 3S").send(:full_house) ).to eq("07|1010100303")
        end
        it "isn't because of number of values" do
          expect( Hand.new("2C 2S 2H 2C 3S").send(:full_house) ).to eq(nil)
        end
        it "isn't because its a straight" do
          expect( Hand.new("2C 3C 4C 5C 6C").send(:full_house) ).to eq(nil)
        end
        it "isn't because its a four of a kind" do
          expect( Hand.new("2C 2S 2H 2S 4C").send(:full_house) ).to eq(nil)
        end
      end

      context "flush" do
        it "is" do
          expect( Hand.new("2C 4C 6C 8C AC").send(:flush) ).to eq("06|1308060402")
        end
        it "isn't because the suites are different" do
          expect( Hand.new("2S 3C 4C 5C 6C").send(:flush) ).to eq(nil)
        end
        it "isn't because its a straight flush" do
          expect( Hand.new("2C 3C 4C 5C 6C").send(:flush) ).to eq(nil)
        end
      end

      context "straight" do
        it "is low" do
          expect( Hand.new("2C 3S 4H 5D 6C").send(:straight) ).to eq("05|0605040302")
        end
        it "is high" do
          expect( Hand.new("9H JH QH KH AH").send(:straight) ).to eq("05|1312111009")
        end
        it "isn't" do
          expect( Hand.new("2C 3C 9C 5C 6C").send(:straight) ).to eq(nil)
        end
      end

      context "three of a kind" do
        it "is with leading values" do
          expect( Hand.new("2C 2S 2H 3C 4S").send(:three_of_a_kind) ).to eq("04|0202020403")
        end
        it "is with traling values" do
          expect( Hand.new("2C 3C 4S 4H 4D").send(:three_of_a_kind) ).to eq("04|0404040302")
        end
        it "is with middle values" do
          expect( Hand.new("2C 4S 4H 4D 3C").send(:three_of_a_kind) ).to eq("04|0404040302")
        end
        it "isn't with 4 of a kind" do
          expect( Hand.new("2C 2S 2H 2D 3C").send(:three_of_a_kind) ).to eq(nil)
        end
        it "isn't with only 2 of a kind" do
          expect( Hand.new("2C 2S 9H 3C 4S").send(:three_of_a_kind) ).to eq(nil)
        end
      end

      context "two pairs" do
        it "is with leading pairs" do
          expect( Hand.new("2C 2S 3C 3S 4H").send(:two_pair) ).to eq("03|0303020204")
        end
        it "is split pairs" do
          expect( Hand.new("2C 2S 3C 4C 4S").send(:two_pair) ).to eq("03|0404020203")
        end
        it "is with trailing pairs" do
          expect( Hand.new("2C 3C 3S 4C 4S").send(:two_pair) ).to eq("03|0404030302")
        end
        it "isn't only one pair" do
          expect( Hand.new("2C 2S 3C 9S 4H").send(:two_pair) ).to eq(nil)
        end
        it "isn't with 4 of a kind" do
          expect( Hand.new("2C 2S 2H 2D 3C").send(:two_pair) ).to eq(nil)
        end
      end

      context "pair" do
        it "is" do
          expect( Hand.new("2C 2S 3C 4C 5C").send(:pair) ).to eq("02|0202050403")
        end
        it "isn't with no pairs" do
          expect( Hand.new("2C 5S 7H 9D AH").send(:pair) ).to eq(nil)
        end
        it "isn't with full house" do
          expect( Hand.new("2C 2S 2H 3C 3S").send(:pair) ).to eq(nil)
        end
        it "isn't three of a kind" do
          expect( Hand.new("2C 2S 2H 4D 3C").send(:pair) ).to eq(nil)
        end
        it "isn't four of a kind" do
          expect( Hand.new("2C 2S 2H 2D 3C").send(:pair) ).to eq(nil)
        end
      end

      context "high card" do
        it "is" do
          expect( Hand.new("2C 4S 6H 7D 8H").send(:high_card) ).to eq("01|0807060402")
        end
        # TODO need exclusion cases.
      end

      context "rank" do

        it "straight flush" do
          expect(Hand.new("2C 3C 4C 5C 6C").send(:rank)).to eq("09|0605040302")
        end
        it "four of a kind" do
          expect(Hand.new("2C 2S 2H 2D 3C").send(:rank)).to eq("08|0202020203")
        end
        it "full house" do
          expect(Hand.new("2C 2S 2H 3D 3C").send(:rank)).to eq("07|0202020303")
        end
        it "flush" do
          expect(Hand.new("2C 3C 5C 7C AC").send(:rank)).to eq("06|1307050302")
        end
        it "straight" do
          expect(Hand.new("9H AH JD KD QD").send(:rank)).to eq("05|1312111009")
        end
        it "three of a kind" do
          expect(Hand.new("6D 6S AH 6H QC").send(:rank)).to eq("04|0606061311")
        end
        it "two pair" do
          expect(Hand.new("2C 2S KD KH QD").send(:rank)).to eq("03|1212020211")
        end
        it "pair" do
          expect(Hand.new("2C 2S 5H 8S KH").send(:rank)).to eq("02|0202120805")
        end
        it "high card" do
          expect(Hand.new("2C 4S 5H 7D QC").send(:rank)).to eq("01|1107050402")
        end
      end

    end
  end

  context Card do

    context "construction" do

      it "with a suit and a vlaue" do
        card = Card.new(:C, Value.two)
        expect(card.suit).to eq(:C)
        expect(card.value).to eq(Value.two)
      end

      it "with a card_code" do
        card = Card.from_code("3S")
        expect(card.suit).to eq(:S)
        expect(card.value).to eq(Value.three)
      end

      it "with invalid card code" do
        expect { Card.from_code("XX") }.to raise_error
      end

    end

    it "compares equal" do
      expect( Card.new(:H, Value.ace) ).to eq( Card.new(:H, Value.ace) )
    end

    it "compares not equal" do
      expect( Card.new(:H, Value.ace) ).not_to eq( Card.new(:C, Value.ace) )
      expect( Card.new(:H, Value.ace) ).not_to eq( Card.new(:H, Value.jack) )
      expect( Card.new(:H, Value.ace) ).not_to eq( nil )
    end

    Deck.suites.each do |suit|
      Value.values.each do |value|
        it "can have values #{suit} #{value}"  do
          expect(Card.new(suit, value).value).to eq(value)
        end
      end
    end

    it "can not have invalid suit" do
      expect { Card.new(:INVALID_SUIT, Value.two) }.to raise_error
    end

    [:"0", :"1", 2, :invalid_value].each do |value|
      it "can not have value #{value}" do
        expect { Card.new(:C, Value.new(value)) }.to raise_error
      end
    end

    context "next card" do
      it "generates the next card" do
        expect( Card.new(:C, Value.two).next_card ).to eq(Card.new(:C, Value.three))
      end

      it "producs jokers if there is no next card" do
        expect( Card.new(:C, Value.ace).next_card ).to eq(Card.joker)
      end
    end

    context "sorts cards by value and" do
      it "finds first greater than second" do
        cards = [Card.new(:C, Value.three), Card.new(:C, Value.two)]

        cards = cards.sort

        expect(cards[0].value).to eq(Value.two)
        expect(cards[1].value).to eq(Value.three)
      end

      it "finds second greater than first" do
        cards = [Card.new(:C, Value.two), Card.new(:C, Value.three)]

        cards = cards.sort

        expect(cards[0].value).to eq(Value.two)
        expect(cards[1].value).to eq(Value.three)
      end
      
      it "finds equal values equal" do
        cards = [Card.new(:C, Value.three), Card.new(:C, Value.three)]

        cards = cards.sort

        expect(cards[0].value).to eq(Value.three)
        expect(cards[1].value).to eq(Value.three)
      end

      it "ignores suit" do
        cards = [Card.new(:S, Value.three), Card.new(:C, Value.three)]

        cards = cards.sort

        expect(cards[0].value).to eq(Value.three)
        expect(cards[1].value).to eq(Value.three)
      end
    end
  end

  context Value do
    it "looks like a symbol" do
      expect( Value.two.to_s ).to eq("2")
      expect( Value.ace.to_s ).to eq("A")
    end

    context "identify" do

      it "equal by value" do
        expect( Value.ace ).to eq(Value.ace)
      end

      it "not equal" do
        expect( Value.two ).not_to eq(Value.three)
      end

      it "mask symbol as raw identify" do
        expect( Value.ace ).to eq(Value.ace)
      end

      it "is not equal if nil" do
        expect( Value.two ).not_to eq(nil)
      end

      context "hash" do
        it "equal" do
          expect( Value.six.hash ).to eq(Value.new(:"6").hash)
        end
        it "not equal" do
          expect( Value.six.hash ).not_to eq(Value.seven.hash)
        end
      end

      context "eql?" do
        it "eql" do
          expect( Value.six.eql?(Value.new(:"6")) ).to eq(true)
        end

        it "not eql" do
          expect( Value.six.eql?(Value.new(:"7")) ).not_to eq(true)
        end
      end
    end

    context "compare" do
      it "greater" do
        expect( Value.three ).to be > Value.two
        expect( Value.jack ).to be > Value.nine
        expect( Value.queen ).to be > Value.jack
        expect( Value.king ).to be > Value.queen
        expect( Value.ace ).to be > Value.king
      end
      it "less" do
        expect( Value.two ).to be < Value.three
        expect( Value.nine ).to be < Value.jack
        expect( Value.jack ).to be < Value.queen
        expect( Value.queen ).to be < Value.king
        expect( Value.king ).to be < Value.ace
      end
    end

    context "sorts by card value" do
      it "sorts ace after king" do
        expect( [Value.ace, Value.king ].sort ).to eq( [Value.king, Value.ace] )
      end
    end

    context "weighs" do

      it "creates a weight from a value" do
        expect( Value.two.weight ).to eq(2)
        expect( Value.nine.weight ).to eq(9)
        expect( Value.jack.weight ).to eq(10)
        expect( Value.queen.weight ).to eq(11)
        expect( Value.king.weight ).to eq(12)
        expect( Value.ace.weight ).to eq(13)
      end

      it "treats all other values as zero" do
        expect( Value.new(:X) .weight).to eq(0)
        expect( Value.new(:joker).weight ).to eq(0)
        expect( Value.new(nil).weight ).to eq(0)
      end
    end
  end
end
