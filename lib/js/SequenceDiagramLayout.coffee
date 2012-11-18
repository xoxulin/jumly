DiagramLayout = require "DiagramLayout"

$.fn.self = -> @data "_self"
$.fn.selfEach = (f)-> @each (i, e)->
  e = $(e).self()
  throw new Error("_self have nothing ", e) unless e?
  f e
  this

class SequenceDiagramLayout extends DiagramLayout

SequenceDiagramLayout::_q = (sel)->
  $ sel, @diagram

SequenceDiagramLayout::_layout_ = ->
  objs = $(".object:eq(0) ~ .object", @diagram)
  $(".object:eq(0)", @diagram).after objs
  @align_objects_horizontally()
  @_q(".occurrence").each (i, e)-> $(e).data("_self")._move_horizontally()
  @_q(".occurrence .interaction").selfEach (e)-> e._compose_()
  @generate_lifelines_and_align_horizontally()
  @pack_refs_horizontally()
  @pack_fragments_horizontally()
  @_q(".create.message").selfEach (e)-> e._to_be_creation()
  @align_lifelines_vertically()
  @align_lifelines_stop_horizontally()
  @rebuild_asynchronous_self_calling()
  @render_icons()

  objs = @diagram.find(".object")
  l = objs.min (e)-> $(e).offset().left
  r = objs.max (e)-> $(e).offset().left + $(e).outerWidth() - 1
  @diagram.width r - l + 1

HTMLElementLayout = require "HTMLElementLayout"

SequenceDiagramLayout::align_objects_horizontally = ->
  f0 = (a)=>
    if a.css("left") is "auto"
      a.css left:0
  f1 = (a, b)=>
    if b.css("left") is "auto"
      spacing = new HTMLElementLayout.HorizontalSpacing(a, b)
      spacing.apply()
  @_q(".object").pickup2 f0, f1

jumly = $.jumly

SequenceLifeline = require "SequenceLifeline"

SequenceDiagramLayout::generate_lifelines_and_align_horizontally = ->
  diag = @diagram
  $(".object", @diagram).each (i, e)->
    obj = $(e).data "_self"
    a = new SequenceLifeline obj
    a.offset left:obj.offset().left
    a.width obj.preferred_width()
    diag.append a

SequenceDiagramLayout::pack_refs_horizontally = ->
  @_q(".ref").selfEach (ref) ->
    pw = ref.preferred_left_and_width()
    ref.offset(left:pw.left)
       .width(pw.width)

SequenceDiagramLayout::pack_fragments_horizontally = ->
  # fragments just under this diagram.
  fragments = $ "> .fragment", @diagram
  if fragments.length > 0
    # To controll the width, you can write selector below.
    # ".object:eq(0), > .interaction > .occurrence .interaction"
    most = @_q(".object").mostLeftRight()
    left = fragments.offset().left
    fragments.width (most.right - left) + (most.left - left)
  
  # fragments inside diagram
  fixwidth = (fragment) ->
    most = $(".occurrence, .message, .fragment", fragment).not(".return, .lost").mostLeftRight()
    fragment.width(most.width() - (fragment.outerWidth() - fragment.width()))
    ## WORKAROUND: it's tentative for both of next condition and the body
    msg = jumly(fragment.find("> .interaction > .message"))[0]
    if (msg?.isTowardLeft())
      fragment.offset(left:most.left)
              .find("> .interaction > .occurrence")
              .each (i, occurr) ->
                occurr = jumly(occurr)[0]
                occurr._move_horizontally()
                      .prev().offset left:occurr.offset().left
  
  @_q(".occurrence > .fragment")
    .selfEach(fixwidth)
    .parents(".occurrence > .fragment")
    .selfEach(fixwidth)

SequenceDiagramLayout::align_lifelines_vertically = ->
  nodes = @diagram.find(".interaction, > .ref")
  return if nodes.length is 0
  
  if nodes.filter(".ref").length > 0
    last = nodes.filter(":last")
    mh = last.offset().top + last.outerHeight() - nodes.filter(":first").offset().top
  else
    mh = @diagram.find(".interaction:eq(0)").height()

  min = @diagram.find(".object").min (e)-> $(e).offset().top

  @_q(".lifeline").each (i, e) ->
    a = $(e).data "_self"
    a.offset left:a._object.offset().left

    ot = Math.ceil a._object.offset().top
    dh = ot - min
    a.height mh - dh + 16

    mt = a.offset().top - (ot + a._object.outerHeight())
    a.css "margin-top":"-#{mt}px"

SequenceDiagramLayout::align_lifelines_stop_horizontally = ->
  $(".stop", @diagram).each (i, e) ->
    e = $(e)
    occurr = e.prev(".occurrence")
    e.offset left:occurr.offset().left

SequenceDiagramLayout::rebuild_asynchronous_self_calling = ->
  @diagram.find(".message.asynchronous").parents(".interaction:eq(0)").each (i, e) ->
    e = $(e).self()
    if not e.isToSelf()
        return
    iact = e.addClass("activated")
            .addClass("asynchronous")
    prev = iact.parents(".interaction:eq(0)")
    iact.insertAfter prev
    
    occurr = iact.css("padding-bottom", 0)
                 .find("> .occurrence").self()
                 ._move_horizontally()
                 .css("top", 0)

    msg = iact.find(".message").self()
    msg.css("z-index", -1)
       .offset
         left: occurr.offset().left
         top : prev.find(".occurrence").outerBottom() - msg.height()/3

SequenceDiagramLayout::render_icons = ->
  @_q(".object").selfEach (e)-> e.renderIcon?()

core = require "core"
if core.env.is_node
  module.exports = SequenceDiagramLayout
else
  core.exports SequenceDiagramLayout
