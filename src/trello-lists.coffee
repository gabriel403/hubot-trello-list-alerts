# Description:
#   Listens for trello notifications on specific lists
#
# Author:
#   gabriel403
#
module.exports = (robot) ->
  trello_list_alerts_actions  = ['createCard', 'commentCard', 'addMemberToCard', 'updateCard']
  trello_list_alerts_list_ids = process.env['HUBOT_TRELLO_LIST_IDS'].split ','
  trello_list_alerts_name     = process.env['HUBOT_TRELLO_ALERT_NAME'] || 'Regression'
  trello_list_webhook_route   = process.env['HUBOT_TRELLO_WEBHOOK_ROUTE'] || '/hubot/trello/regressions'
  trello_list_alerts_channels = (process.env['HUBOT_TRELLO_CHAN_LIST'] || 'support').split ','

  trello_link = "https://trello.com"

  ###########################################################################
  # listen for communication hooks from trello
  #
  robot.router.head trello_list_webhook_route, (req, res) ->
    res.send 'OK'
    return

  robot.router.post trello_list_webhook_route, (req, res) ->
    res.send 'OK'
    return if not isValidCard(req.body.action)

    for channel in trello_list_alerts_channels
      if robot.adapterName is 'slack'
        robot.emit 'slack.attachment',
        content:
          text: msgText(req.body.action)
          fallback: msgText(req.body.action)
        channel: channel
      else
        robot.messageRoom channel, msgText(req.body.action)

    return

  msgText         = (action) ->
    switch action.type
      when 'createCard' then createCardText action
      when 'commentCard' then commentCardText action
      when 'updateCard' then updateCardText action
      # doesn't currently work due to no list object in action.data so doesn't pass validation
      when 'addMemberToCard' then addMemberToCardText action
      else "#{action.type} not understood"

  isValidCard     = (action) ->
    # doesn't pass validation for addMemberToCard due to no list object in action.data
    trello_list_alerts_list_ids and ((action.data.list and action.data.list.id in trello_list_alerts_list_ids) or (action.data.listBefore and action.data.listBefore.id in trello_list_alerts_list_ids) or (action.data.listAfter and action.data.listAfter.id in trello_list_alerts_list_ids)) and action.type in trello_list_alerts_actions

  createCardText  = (action) ->
    "#{trello_list_alerts_name} #{cardLink(action.data.card)} added by #{action.memberCreator.fullName}"

  commentCardText = (action) ->
    """New comment on #{trello_list_alerts_name.toLowerCase()} #{cardLink(action.data.card)} by #{action.memberCreator.fullName}
    #{action.data.text}
    """

  updateCardText = (action) ->
    if "closed" of action.data.card
      if action.data.card.closed
        "#{trello_list_alerts_name} #{cardLink(action.data.card)} archived by #{action.memberCreator.fullName}"
      else
        "#{trello_list_alerts_name} #{cardLink(action.data.card)} un-archived by #{action.memberCreator.fullName}"
    else if "listAfter" of action.data and "listBefore" of action.data
        "#{trello_list_alerts_name} #{cardLink(action.data.card)} moved to #{action.data.listAfter.name} by #{action.memberCreator.fullName}"
    else
      "I don't know what to do with this."
      console.log action

  # doesn't currently work due to no list object in action.data so doesn't pass validation
  addMemberToCardText = (action) ->
    "New member #{action.member.fullName} added to #{trello_list_alerts_name.toLowerCase()} #{cardLink(action.data.card)}"

  cardLink        = (card) ->
    "<#{trello_link}/c/#{card.shortLink}|#{card.name}>"

  boardLink       = (board)->
    "<#{trello_link}/b/#{board.shortLink}|#{board.name}>"

