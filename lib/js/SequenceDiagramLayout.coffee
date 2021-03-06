DiagramLayout = require "DiagramLayout.coffee"
utils = require "jquery.ext.coffee"

class SequenceDiagramLayout extends DiagramLayout

SequenceDiagramLayout::_q = (sel)->
  $ sel, @diagram

SequenceDiagramLayout::_layout = ->
  objs = $(".participant:eq(0) ~ .participant", @diagram)
  $(".participant:eq(0)", @diagram).after objs
  @align_objects_horizontally()
  @_q(".occurrence").each (i, e)-> $(e).data("_self")._move_horizontally()
  utils.selfEach @_q(".occurrence .interaction"), (e)-> e._compose_()
  @generate_lifelines_and_align_horizontally()
  @pack_refs_horizontally()
  @pack_fragments_horizontally()
  utils.selfEach @_q(".create.message"), (e)-> e._to_be_creation()
  @align_lifelines_vertically()
  @align_lifelines_stop_horizontally()
  @rebuild_asynchronous_self_calling()
  @render_icons()

  occurs = @diagram.find ".occurrence"
  ml = occurs.sort (e)-> $(e).offset().left
  mr = occurs.sort (e)-> $(e).offset().left + $(e).outerWidth() - 1
  $(ml[0]).addClass "leftmost"
  $(mr[mr.length - 1]).addClass "rightmost"

  objs = @diagram.find(".participant")
  l = utils.min objs, (e)-> $(e).offset().left
  r = utils.max objs, (e)-> $(e).offset().left + $(e).outerWidth() - 1
  @diagram.width r - l + 1

HTMLElementLayout = require "HTMLElementLayout.coffee"

_ = (opts)->
  if navigator?.userAgent.match(/.*(WebKit).*/)
    return opts["webkit"]
  if navigator?.userAgent.match(/.*(Gecko).*/)
    return opts["gecko"]
  return opts["webkit"]

SequenceDiagramLayout::align_objects_horizontally = ->
  f0 = (a)=>
    if a.css("left") is (_ webkit:"auto", gecko:"0px")
      a.css left:0
  f1 = (a, b)=>
    if b.css("left") is (_ webkit:"auto", gecko:"0px")
      spacing = new HTMLElementLayout.HorizontalSpacing(a, b)
      spacing.apply()
  utils.pickup2 @_q(".participant"), f0, f1

SequenceLifeline = require "SequenceLifeline.coffee"

SequenceDiagramLayout::generate_lifelines_and_align_horizontally = ->
  diag = @diagram
  $(".participant", @diagram).each (i, e)->
    obj = $(e).data "_self"
    a = new SequenceLifeline obj
    a.offset left:obj.offset().left
    a.width obj.preferred_width()
    diag.append a

SequenceDiagramLayout::pack_refs_horizontally = ->
  utils.selfEach @_q(".ref"), (ref) ->
    pw = ref.preferred_left_and_width()
    ref.offset(left:pw.left)

    ## workaround for checking width of css is defined
    idx = ref.index()
    parent = ref.parent()
    ref.detach()
    not_defined = ref.css("width") is "0px"
    if idx is 0
      parent.prepend ref
    else
      ref.insertAfter parent.find("> *:eq(#{idx-1})")

    if not_defined
      ref.width pw.width
    else
      ref.width parseInt ref.css "width"

SequenceDiagramLayout::pack_fragments_horizontally = ->
  # fragments just under this diagram.
  fragments = $ "> .fragment", @diagram
  if fragments.length > 0
    # To controll the width, you can write selector below.
    # ".participant:eq(0), > .interaction > .occurrence .interaction"
    most = utils.mostLeftRight @_q(".participant")
    left = fragments.offset().left
    fragments.width (most.right - left) + (most.left - left)
  
  # fragments inside diagram
  fixwidth = (fragment) ->
    most = utils.mostLeftRight $(".occurrence, .message, .fragment", fragment).not(".return, .lost")
    fragment.width(most.width() - (fragment.outerWidth() - fragment.width()))
    ## WORKAROUND: it's tentative for both of next condition and the body
    msg = fragment.find("> .interaction > .message").data "_self"
    if (msg?.isTowardLeft())
      fragment.offset(left:most.left)
              .find("> .interaction > .occurrence")
              .each (i, occurr) ->
                occurr = occurr.data "_self"
                occurr._move_horizontally()
                      .prev().offset left:occurr.offset().left
  
  a = (utils.selfEach @_q(".occurrence > .fragment"), fixwidth)
    .parents(".occurrence > .fragment")
  utils.selfEach a, fixwidth

SequenceDiagramLayout::align_lifelines_vertically = ->
  nodes = @diagram.find(".interaction, > .ref")
  return if nodes.length is 0
  
  if nodes.filter(".ref").length > 0
    last = nodes.filter(":last")
    mh = last.offset().top + last.outerHeight() - nodes.filter(":first").offset().top
  else
    if (iters = @diagram.find("> .interaction")).length is 1
      mh = iters.filter(":eq(0)").height()
    else
      a = iters.filter(":eq(0)")
      b = iters.filter(":last")
      mh = (b.offset().top + b.height() - 1) - a.offset().top

  min = utils.min @diagram.find(".participant"), (e)-> $(e).offset().top

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
    e = utils.self $(e)
    if not e.isToSelf()
        return
    iact = e.addClass("activated")
            .addClass("asynchronous")
    prev = iact.parents(".interaction:eq(0)")
    iact.insertAfter prev
   
    aa = utils.self iact.css("padding-bottom", 0).find("> .occurrence")
    occurr = aa._move_horizontally()
               .css("top", 0)

    msg = utils.self iact.find(".message")
    msg.css("z-index", -1)
       .offset
         left: occurr.offset().left
         top : utils.outerBottom(prev.find(".occurrence")) - msg.height()/3

SequenceDiagramLayout::render_icons = ->
  utils.selfEach @_q(".participant"), (e)-> e.renderIcon?()

module.exports = SequenceDiagramLayout
