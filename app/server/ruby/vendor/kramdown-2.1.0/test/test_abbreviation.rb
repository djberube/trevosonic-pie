# -*- coding: utf-8; frozen_string_literal: true -*-
#
#--
# Copyright (C) 2009-2019 Thomas Leitner <t_leitner@gmx.at>
#
# This file is part of kramdown which is licensed under the MIT.
#++

require 'minitest/autorun'
require 'kramdown'

describe 'abbreviation parsing' do
  # Test parse_abbrev_definition method
  describe 'parse_abbrev_definition' do
    it 'parses valid abbreviation definition' do
      doc = Kramdown::Document.new("*[HTML]: HyperText Markup Language\n\n")
      assert_equal 'HyperText Markup Language', doc.root.options[:abbrev_defs]['HTML']
      # The :eob element gets removed during update_tree
      assert_equal 1, doc.root.children.size
      assert_equal :blank, doc.root.children.first.type
    end

    it 'strips whitespace from abbreviation text' do
      doc = Kramdown::Document.new("*[CSS]:   Cascading Style Sheets   \n\n")
      assert_equal 'Cascading Style Sheets', doc.root.options[:abbrev_defs]['CSS']
    end

    it 'handles empty abbreviation text' do
      doc = Kramdown::Document.new("*[EMPTY]:\n\n")
      assert_equal '', doc.root.options[:abbrev_defs]['EMPTY']
    end

    it 'handles abbreviation with special characters in id' do
      doc = Kramdown::Document.new("*[C++]: Programming Language\n\n")
      assert_equal 'Programming Language', doc.root.options[:abbrev_defs]['C++']
    end

    it 'handles abbreviation with spaces in id' do
      doc = Kramdown::Document.new("*[World Wide Web]: WWW\n\n")
      assert_equal 'WWW', doc.root.options[:abbrev_defs]['World Wide Web']
    end

    it 'overwrites duplicate abbreviation definitions with warning' do
      doc = Kramdown::Document.new("*[DUPE]: First\n*[DUPE]: Second\n\n")
      assert_equal 'Second', doc.root.options[:abbrev_defs]['DUPE']
      assert_equal 1, doc.warnings.size
      assert_match(/Duplicate abbreviation ID 'DUPE' on line 2/, doc.warnings.first)
    end

    it 'handles multiple abbreviation definitions' do
      text = "*[HTML]: HyperText Markup Language\n*[CSS]: Cascading Style Sheets\n*[JS]: JavaScript\n\n"
      doc = Kramdown::Document.new(text)
      assert_equal 'HyperText Markup Language', doc.root.options[:abbrev_defs]['HTML']
      assert_equal 'Cascading Style Sheets', doc.root.options[:abbrev_defs]['CSS']
      assert_equal 'JavaScript', doc.root.options[:abbrev_defs]['JS']
    end

    it 'handles abbreviation with colon in text' do
      doc = Kramdown::Document.new("*[TIME]: 12:30 PM\n\n")
      assert_equal '12:30 PM', doc.root.options[:abbrev_defs]['TIME']
    end

    it 'handles abbreviation with brackets in text' do
      doc = Kramdown::Document.new("*[ARRAY]: [1, 2, 3]\n\n")
      assert_equal '[1, 2, 3]', doc.root.options[:abbrev_defs]['ARRAY']
    end

    it 'handles unicode characters in abbreviation' do
      doc = Kramdown::Document.new("*[CÆSAR]: Roman Emperor\n\n")
      assert_equal 'Roman Emperor', doc.root.options[:abbrev_defs]['CÆSAR']
    end

    it 'handles very long abbreviation id' do
      long_id = 'A' * 1000
      doc = Kramdown::Document.new("*[#{long_id}]: Long abbreviation\n\n")
      assert_equal 'Long abbreviation', doc.root.options[:abbrev_defs][long_id]
    end

    it 'handles very long abbreviation text' do
      long_text = 'A' * 10000
      doc = Kramdown::Document.new("*[LONG]: #{long_text}\n\n")
      assert_equal long_text, doc.root.options[:abbrev_defs]['LONG']
    end
  end

  # Test correct_abbreviations_attributes method (tested through integration)
  describe 'correct_abbreviations_attributes' do
    it 'sets abbrev_attr values to element attributes during parsing' do
      doc = Kramdown::Document.new("*[TEST]: Test abbreviation\n\nUse TEST here.\n")
      html = doc.to_html
      assert_match(/<abbr title="Test abbreviation">TEST<\/abbr>/, html)
    end
  end

  # Test replace_abbreviations method
  describe 'replace_abbreviations' do
    it 'replaces single abbreviation in text' do
      doc = Kramdown::Document.new("*[HTML]: HyperText Markup Language\n\nThis is HTML.\n")
      assert_equal 2, doc.root.children.size # blank + p
      para = doc.root.children.last
      assert_equal :p, para.type
      assert_equal 3, para.children.size
      assert_equal 'This is ', para.children[0].value
      assert_equal :abbreviation, para.children[1].type
      assert_equal 'HTML', para.children[1].value
      assert_equal '.', para.children[2].value
    end

    it 'replaces multiple instances of same abbreviation' do
      doc = Kramdown::Document.new("*[CSS]: Cascading Style Sheets\n\nCSS and CSS are great.\n")
      para = doc.root.children.last
      assert_equal 5, para.children.size
      assert_equal 'CSS', para.children[1].value
      assert_equal ' and ', para.children[2].value
      assert_equal 'CSS', para.children[3].value
    end

    it 'replaces multiple different abbreviations' do
      doc = Kramdown::Document.new("*[HTML]: HyperText Markup Language\n*[CSS]: Cascading Style Sheets\n\nHTML and CSS.\n")
      para = doc.root.children.last
      assert_equal :abbreviation, para.children[1].type
      assert_equal 'HTML', para.children[1].value
      assert_equal ' and ', para.children[2].value
      assert_equal :abbreviation, para.children[3].type
      assert_equal 'CSS', para.children[3].value
    end

    it 'handles abbreviations at word boundaries' do
      doc = Kramdown::Document.new("*[the]: definite article\n\nthe theatre is great.\n")
      para = doc.root.children.last
      # 'the' should be replaced, 'the' in 'theatre' should not
      assert_equal 'the', para.children[1].value
      assert_equal ' theatre is great.', para.children[2].value
    end

    it 'handles abbreviations with special regex characters' do
      doc = Kramdown::Document.new("*[C++]: Programming Language\n\nI love C++.\n")
      para = doc.root.children.last
      assert_equal :abbreviation, para.children[1].type
      assert_equal 'C++', para.children[1].value
    end

    it 'handles abbreviations in nested elements' do
      doc = Kramdown::Document.new("*[HTML]: HyperText Markup Language\n\n**Bold HTML text.**\n")
      para = doc.root.children.last # Skip the blank line
      strong = para.children[0]
      assert_equal :strong, strong.type
      assert_equal 'Bold ', strong.children[0].value
      assert_equal :abbreviation, strong.children[1].type
      assert_equal 'HTML', strong.children[1].value
    end

    it 'handles empty abbreviation definitions' do
      doc = Kramdown::Document.new("*[EMPTY]:\n\nThis is EMPTY.\n")
      para = doc.root.children.last
      assert_equal 'This is ', para.children[0].value
      assert_equal :abbreviation, para.children[1].type
      assert_equal 'EMPTY', para.children[1].value
    end

    it 'does not replace when no abbreviations defined' do
      doc = Kramdown::Document.new("This is plain text.\n")
      para = doc.root.children.first
      assert_equal 1, para.children.size
      assert_equal :text, para.children[0].type
      assert_equal 'This is plain text.', para.children[0].value
    end

    it 'handles abbreviations with unicode characters' do
      doc = Kramdown::Document.new("*[CÆSAR]: Roman Emperor\n\nCÆSAR was great.\n")
      para = doc.root.children.last
      assert_equal :abbreviation, para.children[1].type
      assert_equal 'CÆSAR', para.children[1].value
    end

    it 'handles abbreviations sorted by length descending' do
      # Test that longer abbreviations are matched before shorter ones
      doc = Kramdown::Document.new("*[ABC]: Alphabet\n*[AB]: Not alphabet\n\nABC is good.\n")
      para = doc.root.children.last
      assert_equal :abbreviation, para.children[1].type
      assert_equal 'ABC', para.children[1].value
    end

    it 'handles complex text with multiple replacements' do
      text = "*[API]: Application Programming Interface\n*[HTTP]: HyperText Transfer Protocol\n\nThe API uses HTTP.\n"
      doc = Kramdown::Document.new(text)
      para = doc.root.children.last
      assert_equal 'The ', para.children[0].value
      assert_equal :abbreviation, para.children[1].type
      assert_equal 'API', para.children[1].value
      assert_equal ' uses ', para.children[2].value
      assert_equal :abbreviation, para.children[3].type
      assert_equal 'HTTP', para.children[3].value
      assert_equal '.', para.children[4].value
    end

    it 'preserves location information' do
      doc = Kramdown::Document.new("*[TEST]: Test\n\nLine with TEST.\n")
      para = doc.root.children.last
      abbr = para.children[1]
      assert_equal :abbreviation, abbr.type
      assert abbr.options[:location]
    end
  end

  # Integration tests
  describe 'integration' do
    it 'full abbreviation processing works' do
      text = "*[HTML]: HyperText Markup Language\n*[CSS]: Cascading Style Sheets\n\nHTML and CSS are web technologies.\n"
      doc = Kramdown::Document.new(text)
      html = doc.to_html

      assert_match(/<abbr title="HyperText Markup Language">HTML<\/abbr>/, html)
      assert_match(/<abbr title="Cascading Style Sheets">CSS<\/abbr>/, html)
    end

    it 'abbreviations work with other markdown elements' do
      text = "*[JS]: JavaScript\n\n- List with JS\n- Another JS item\n\n**Bold JS code.**\n"
      doc = Kramdown::Document.new(text)
      html = doc.to_html

      assert_match(/<abbr title="JavaScript">JS<\/abbr>/, html)
      assert_match(/<ul>/, html)
      assert_match(/<strong>/, html)
    end
  end

  # Edge cases and error conditions
  describe 'edge cases' do
    it 'handles abbreviation id with only special characters' do
      doc = Kramdown::Document.new("*[+++]: Plus signs\n\n+++ is special.\n")
      para = doc.root.children.last
      assert_equal :abbreviation, para.children[1].type
      assert_equal '+++', para.children[1].value
    end

    it 'handles abbreviation text with newlines' do
      # The regex stops at the first newline, so only "Line 1" is captured
      doc = Kramdown::Document.new("*[MULTI]: Line 1\nLine 2\n\nThis is MULTI.\n")
      assert_equal "Line 1", doc.root.options[:abbrev_defs]['MULTI']
    end

    it 'handles very nested element structures' do
      text = "*[ABBR]: Abbreviation\n\n*italic **bold ABBR** italic*\n"
      doc = Kramdown::Document.new(text)
      para = doc.root.children.last
      em = para.children[0]
      strong = em.children[1]
      abbr = strong.children[1]
      assert_equal :abbreviation, abbr.type
      assert_equal 'ABBR', abbr.value
    end
  end
end