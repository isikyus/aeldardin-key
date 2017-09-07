Feature: Show a warning if the document contains fields we can't process

  If you use a field Aeldardin doesn't know about in your document, it won't
  get parsed, and whatever you put in it will disappear when you build the
  HTML/graphviz/etc. document.

  This is really annoying, but sometimes unavoidable given the number of
  things that don't work yet, so we output a warning when parsing a document
  with unknown fields.

  Background:
    Given a file named "dungeon.yml" with:
    """
    #%YAML 1.2
    ---
    title: Test Dungeon

    ideas:
      - a
      - b
      - c

    zones:
      - id: 'test'
        notes: 'some gibberish'
    """

  Scenario: Heading Structure
    When I successfully run `aeldardin html dungeon.yml`
    Then there should be a warning 'Unrecognised field "ideas"'
    And there should be a warning 'Unrecognised field "zones.notes"'
    And the stdout should have the title "Test Dungeon"
    
