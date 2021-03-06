$ = require "jquery"
HTMLElement = require "HTMLElement.coffee"

class SequenceParticipant extends HTMLElement
  constructor: (args)->
    super args, (me)->
      me.append($("<div>").addClass("name"))

SequenceOccurrence = require "SequenceOccurrence.coffee"
SequenceInteraction = require "SequenceInteraction.coffee"

SequenceParticipant::activate = ->
  occurr = new SequenceOccurrence this
  iact = new SequenceInteraction null, occurr
  iact.addClass "activated"
  iact.find(".message").remove()
  iact.append(occurr)
  @parent().append(iact)
  occurr

SequenceParticipant::isLeftAt = (a)-> @offset().left < a.offset().left

SequenceParticipant::isRightAt = (a)-> (a.offset().left + a.width()) < @offset().left

SequenceParticipant::iconify = (fixture, styles)->
  unless typeof fixture is "function"
    fixture = $.jumly.icon["." + fixture] || $.jumly.icon[".actor"]
  canvas = $("<canvas>").addClass("icon")
  container = $("<div>").addClass("icon-container")
  @addClass("iconified").prepend(container.append canvas)

  {size, styles} = fixture canvas[0], styles
  container.css height:size.height #, width:size.width ##FIXME: Way to decide the width.
  render = =>
    name = @find(".name")
    styles.fillStyle   = name.css("background-color")
    styles.strokeStyle = name.css("border-top-color")
    fixture canvas[0], styles
  this.renderIcon = -> render()
  this

SequenceParticipant::lost =-> @activate().interact(null, {stereotype:".lost"})

module.exports = SequenceParticipant
