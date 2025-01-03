--- STEAMODDED HEADER
--- MOD_NAME: Reddit Jokers
--- MOD_ID: RedditJokers
--- MOD_AUTHOR: [DanielTheManiel]
--- MOD_DESCRIPTION: Jokers designed by r/Balatro!
--- VERSION: 1.0
--- BADGE_COLOR: ff4500

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Atlas {
  key = "modicon",
  path = "modIcon.png",
  px = 32,
  py = 32
}

SMODS.Atlas {
  key = "RedditJokers",
  path = "RedditJokers.png",
  px = 71,
  py = 95
}

SMODS.Atlas {
  key = "RedditSpectrals",
  path = "RedditSpectrals.png",
  px = 63,
  py = 93
}

SMODS.Joker { -- Embroidery: https://www.reddit.com/r/balatro/comments/1hetxia/
  key = 'embroidery',
  loc_txt = {
    name = 'Embroidery',
    text = {
      "When a blind is selected,",
      "lose all but {C:attention}1{} hand.",
      "Gain {X:mult,C:white}X#2#{} Mult for each",
      "hand lost this way.",
      "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)"
    }
  },
  config = { extra = { xmult = 1, xmult_gain = 0.25 } },
  rarity = 3,
  atlas = 'RedditJokers',
  pos = {x = 0, y = 2},
  cost = 6,
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.xmult, card.ability.extra.xmult_gain } }
  end,
  calculate = function(self, card, context)
    if context.joker_main then
      return {
        message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.xmult } },
        Xmult_mod = card.ability.extra.xmult
      }
    end
    if context.setting_blind and not context.blueprint_card then
      removeHands = G.GAME.current_round.hands_left - 1
      card.ability.extra.xmult = card.ability.extra.xmult + removeHands*card.ability.extra.xmult_gain
      ease_hands_played(-removeHands)
      delay(1)
      card_eval_status_text(
        card,
        'extra',
        nil, nil, nil,
        {message = localize('k_upgrade_ex'), colour = G.C.RED}
      )
    end
  end
}

SMODS.Joker { -- Lucky Sevens: https://www.reddit.com/r/balatro/comments/1en536r/
  key = 'luckysevens',
  loc_txt = {
    name = 'Lucky Sevens',
    text = {
      "Each played {C:attention}7{} has a",
      "{C:green}#1# in 2{} chance for {C:red}+7{} Mult",
      "and a {C:green}#1# in 2{} chance for {C:money}$7",
      "when scored"
    }
  },
  rarity = 2,
  atlas = 'RedditJokers',
  pos = {x = 1, y = 0},
  cost = 5,
  loc_vars = function(self, info_queue, card)
    return { vars = {G.GAME.probabilities.normal or 1}}
  end,
  calculate = function(self,card,context)
    if context.individual and context.cardarea == G.play and context.other_card:get_id() == 7 then
      if pseudorandom('luckysevens'..G.SEED) < G.GAME.probabilities.normal / 2 then
        ease_dollars(7)
        card_eval_status_text(
          context.other_card,
          'extra',
          nil, nil, nil,
          {message = '$7', colour = G.C.MONEY}
        )
      end
      if pseudorandom('luckysevens'..G.SEED) < G.GAME.probabilities.normal / 2 then
        return{
          mult = 7,
          card = context.other_card
        }
      end
    end
  end
}

SMODS.Joker { -- Clogged Toilet: https://www.reddit.com/r/balatro/comments/1drb7au/
  key = 'cloggedtoilet',
  name = 'Clogged Toilet', --Needed for find_joker()
  loc_txt = {
    name = 'Clogged Toilet',
    text = {
      "Instead of scoring, playing",
      "a {C:attention}Flush{} upgrades last played",
      "scoring hand by {C:attention}2{} levels",
      "{C:inactive}(Last scored: #1#)"
    }
  },
  rarity = 3, -- Too high?
  config = { levelUp = 'None' },
  atlas = 'RedditJokers',
  pos = {x = 2, y = 0},
  cost = 6,
  loc_vars = function(self, info_queue, card)
    return {vars = {card.ability.levelUp}}
  end,
  calculate = function(self,card,context)
    if context.after and G.GAME.last_hand_played ~= 'Flush' then
      card.ability.levelUp = G.GAME.last_hand_played
    end
  end
}

--- BIG Omicra98 SECTION ---
-- https://www.reddit.com/r/balatro/comments/1hnbwvn/
-- Costs are guesstimates

SMODS.Consumable{ -- Skyfall
  set = 'Spectral',
  key = 'skyfall',
  loc_txt = {
    name = 'Skyfall',
    text = {
      "Add #1# extra {C:attention}Voucher{} to",
      "current shop, gives a",
      "random {C:attention}Joker{} an {C:purple}Eternal tag"
    }
  },
  config = {vouchers = 1},
  atlas = 'RedditSpectrals',
  pos = {x=0,y=0},
  cost = 4,
  loc_vars = function(self, info_queue)
    return {vars = {self.config.vouchers}}
  end,
  can_use = function(self, card)
    if G.STATE == G.STATES.SHOP or G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.TAROT_PACK then
      return true
    end
    return false
  end,
  use = function(self, card)
    -- Taken from voucher tag code
    local voucher_key = get_next_voucher_key(true)
    G.shop_vouchers.config.card_limit = G.shop_vouchers.config.card_limit + 1
    local card = Card(G.shop_vouchers.T.x + G.shop_vouchers.T.w/2,
    G.shop_vouchers.T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS[voucher_key],{bypass_discovery_center = true, bypass_discovery_ui = true})
    create_shop_card_ui(card, 'Voucher', G.shop_vouchers)
    card:start_materialize()
    G.shop_vouchers:emplace(card)

    -- Apply Eternal to random joker
    local canEternal = {}
    for _, j in ipairs(G.jokers.cards) do
      if not j.ability.perishable and j.config.center.eternal_compat then
        table.insert(canEternal,j)
      end
    end
    local makeEternal = pseudorandom_element(canEternal, pseudoseed('skyfall'))
    if makeEternal then makeEternal:set_eternal(true) end
  end
}

SMODS.Joker{ -- Crimson Dawn
  key = 'crimsondawn',
  loc_txt = {
    name = 'Crimson Dawn',
    text = {
      "Retrigger all played",
      "cards in {C:attention}first hand{} of",
      "round"
    }
  },
  rarity = 3,
  atlas = 'RedditJokers',
  pos = {x=3,y=0},
  cost = 6,
  calculate = function(self,card,context)
    if G.GAME.current_round.hands_played == 0 and context.cardarea == G.play and context.repetition and not context.repetition_only then
      return {
        message = localize('k_again_ex'),
        repetitions = 1,
        card = context.other_card
      }
    end
  end
}

SMODS.Joker{ -- Pier
  key = 'pier',
  loc_txt = {
    name = 'Pier',
    text = {
      "If {C:attention}first discard{} of round",
      "has only {C:attention}1{} card, add a",
      "random {C:attention}seal{} to that card"
    }
  },
  rarity = 2,
  atlas = 'RedditJokers',
  pos = {x=4,y=0},
  cost = 5,
  calculate = function(self,card,context)
    if context.discard and G.GAME.current_round.discards_used <= 0 and #context.full_hand == 1 then
      local card = context.full_hand[1]
      local seal_type = pseudorandom(pseudoseed('stdsealtype'..G.GAME.round_resets.ante))
      if seal_type > 0.75 then card:set_seal('Red')
      elseif seal_type > 0.5 then card:set_seal('Blue')
      elseif seal_type > 0.25 then card:set_seal('Gold')
      else card:set_seal('Purple')
      end
      card:juice_up()
    end
  end
}

SMODS.Joker{ -- Rover
  key = 'rover',
  loc_txt = {
    name = 'Rover',
    text = {
      "Gain {C:red}+#2#{} Mult per {C:attention}Stone",
      "{C:attention}Card{} scored",
      "{C:inactive}(Currently {C:red}+#1# {C:inactive}Mult)"
    }
  },
  config = {mult = 0, mult_gain = 1},
  rarity = 2,
  atlas = 'RedditJokers',
  pos = {x=5,y=0},
  cost = 4,
  loc_vars = function(self,info_queue,card)
    return {vars = {card.ability.mult, card.ability.mult_gain}}
  end,
  calculate = function(self,card,context)
    if context.joker_main then
      return {
        message = localize { type = 'variable', key = 'a_mult', vars = { card.ability.mult } },
        mult_mod = card.ability.mult
      }
    end
    if context.individual and context.other_card.ability.effect == 'Stone Card' then
      card.ability.mult = card.ability.mult + card.ability.mult_gain
      card_eval_status_text(
        card,
        'extra',
        nil, nil, nil,
        {message = localize('k_upgrade_ex'), colour = G.C.RED}
      )
    end
  end
}

SMODS.Joker{ -- Snake Nest
  key = 'snakenest',
  id = 'snakenest',
  name = 'Snake Nest',
  loc_txt = {
    name = 'Snake Nest',
    text = {
      "All listed probabilities are",
      "reduced to {C:green}0"
    }
  },
  rarity = 2,
  atlas = 'RedditJokers',
  pos = {x=6,y=0},
  cost = 4,
  add_to_deck = function(self, card, from_debuff)
    for k, _ in pairs(G.GAME.probabilities) do 
      G.GAME.probabilities[k] = 0
    end
  end,
  remove_from_deck = function(self, card, from_debuff)
    if #find_joker('Snake Nest') == 0 then
      local oopses = #find_joker('Oops! All 6s')
      for k, _ in pairs(G.GAME.probabilities) do 
        G.GAME.probabilities[k] = 2^oopses
      end
    end
  end
}

SMODS.Joker{ -- Album Cover
  key = 'albumcover',
  name = 'Album Cover',
  loc_txt = {
    name = 'Album Cover',
    text = {
      "All {C:attention}Booster Packs{} contain",
      "an extra card"
    }
  },
  rarity = 1,
  atlas = 'RedditJokers',
  pos = {x=0,y=1},
  cost = 4
}

SMODS.Joker{ -- Sheet Music
  key = 'sheetmusic',
  loc_txt = {
    name = 'Sheet Music',
    text = {
      "Gain {C:money}$#1#{} when each played",
      "{C:attention}Ace{}, {C:attention}2{}, {C:attention}3{}, or {C:attention}4{} is scored"
    }
  },
  config = {money_gain = 1},
  rarity = 1,
  atlas = 'RedditJokers',
  pos = {x=1,y=1},
  cost = 4,
  loc_vars = function(self,info_queue,card)
    return {vars = {card.ability.money_gain}}
  end,
  calculate = function(self,card,context)
    if context.individual and context.cardarea == G.play and (context.other_card:get_id() == 2 or context.other_card:get_id() == 3 or context.other_card:get_id() == 4 or context.other_card:get_id() == 14) then
      ease_dollars(1)
      card_eval_status_text(
        context.other_card,
        'extra',
        nil, nil, nil,
        {message = '$1', colour = G.C.MONEY}
      )
    end
  end
}

SMODS.Joker{ -- The Solitary
  key = 'solitary',
  loc_txt = {
    name = 'The Solitary',
    text = {
      "Gain {X:mult,C:white}X#2#{} Mult per {C:attention}High",
      "{C:attention}Card{} played, resets when",
      "{C:attention}Boss Blind{} is defeated",
      "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)"
    }
  },
  config = {x_mult = 1, x_mult_gain = 0.25},
  rarity = 3,
  atlas = 'RedditJokers',
  pos = {x=2,y=1},
  cost = 6,
  loc_vars = function(self,info_queue,card)
    return {vars = {card.ability.x_mult, card.ability.x_mult_gain}}
  end,
  calculate = function(self,card,context)
    if context.joker_main then
      return {
        message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.x_mult } },
        Xmult_mod = card.ability.x_mult
      }
    end
    if context.before and next(context.poker_hands["High Card"]) then
      card.ability.x_mult = card.ability.x_mult + card.ability.x_mult_gain
      card_eval_status_text(
        card,
        'extra',
        nil, nil, nil,
        {message = localize('k_upgrade_ex'), colour = G.C.RED}
      )
    end
    if context.end_of_round and G.GAME.blind.boss and card.ability.x_mult > 1 then
      card.ability.x_mult = 1
      return {
        message = localize('k_reset'),
        colour = G.C.RED
      }
    end
  end
}

SMODS.Joker{ -- Superstition
  key = 'superstition',
  name = 'Superstition',
  loc_txt = {
    name = 'Superstition',
    text = {
      "Gain {X:mult,C:white}X#2#{} Mult per {C:attention}7{} in",
      "deck, remove {X:mult,C:white}X#2#{} Mult",
      "per {C:attention}6{} in deck",
      "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)"
    }
  },
  config = {Xmult = 1, Xmult_change = 0.25, six_tally = 4, seven_tally = 4},
  rarity = 3,
  atlas = 'RedditJokers',
  pos = {x=3,y=1},
  cost = 6,
  loc_vars = function(self,info_queue,card)
    return {vars = {card.ability.Xmult, card.ability.Xmult_change}}
  end,
  calculate = function(self,card,context)
    if context.joker_main then
      return {
        message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.Xmult } },
        Xmult_mod = card.ability.Xmult
      }
    end
  end
}

SMODS.Joker{ -- Hollow Point
  key = 'hollow_point',
  name = 'Hollow Point',
  loc_txt = {
    name = 'Hollow Point',
    text={
      "{C:mult}+5{} Mult for each",
      "empty {C:attention}Joker{} slot",
      "{s:0.8}Hollow Point and Stencil included",
      "{C:inactive}(Currently {C:mult}+#1#{C:inactive})"
    }
  },
  config = {mult = 0},
  rarity = 1,
  atlas = 'RedditJokers',
  pos = {x=4,y=1},
  cost = 4,
  loc_vars = function(self,info_queue,card)
    return {vars = {card.ability.mult}}
  end,
  calculate = function(self,card,context)
    if context.joker_main then
      return {
        message = localize { type = 'variable', key = 'a_mult', vars = { card.ability.mult } },
        mult_mod = card.ability.mult
      }
    end
  end
}

SMODS.Joker{ -- Pharaoh
  key = 'pharaoh',
  loc_txt = {
    name = 'Pharaoh',
    text = {
      "{X:mult,C:white}X#1#{} Mult when money held",
      "is greater than {C:money}$#2#{}.",
      "Increases by {C:money}$#3#{} per Ante"
    }
  },
  config = {XmultBase = 3, moneyMin = 25, moneyAdd = 5, lastAnteUpdate = 0},
  rarity = 3,
  atlas = 'RedditJokers',
  pos = {x=5,y=1},
  cost = 6,
  loc_vars = function(self,info_queue,card)
    return {vars = {card.ability.XmultBase, card.ability.moneyMin, card.ability.moneyAdd}}
  end,
  add_to_deck = function(self,card,context)
    card.ability.lastAnteUpdate = G.GAME.round_resets.ante - 1
  end,
  calculate = function(self,card,context)
    if context.joker_main then
      if G.GAME.dollars > card.ability.moneyMin then
        return {
          message = localize {type = 'variable', key = 'a_xmult', vars = {card.ability.XmultBase}},
          Xmult_mod = card.ability.XmultBase
        }
      else
        card_eval_status_text(
          card,
          'extra',
          nil, nil, nil,
          {message = 'Broke!', colour = G.C.MONEY}
        )
      end
    end
    if context.end_of_round and G.GAME.blind.boss and G.GAME.round_resets.ante > card.ability.lastAnteUpdate then
      card.ability.moneyMin = card.ability.moneyMin + card.ability.moneyAdd
      card_eval_status_text(
        card,
        'extra',
        nil, nil, nil,
        {message = localize('k_upgrade_ex'), colour = G.C.MONEY}
      )
      card.ability.lastAnteUpdate = G.GAME.round_resets.ante
    end
  end
}

SMODS.Joker{ -- Aurora
  key = 'aurora',
  loc_txt = {
    name = 'Aurora',
    text = {
      "Gain {C:chips}+#2#{} Chips per unique",
      "hand type played this",
      "round",
      "{C:inactive}(Currently {C:chips}+#1#{C:inactive})"
    }
  },
  config = {chips = 0, chips_gain = 10, hands = {
    ["Flush Five"] = false,
    ["Flush House"] = false,
    ["Five of a Kind"] = false,
    ["Straight Flush"] = false,
    ["Four of a Kind"] = false,
    ["Full House"] = false,
    ["Flush"] = false,
    ["Straight"] = false,
    ["Three of a Kind"] = false,
    ["Two Pair"] = false,
    ["Pair"] = false,
    ["High Card"] = false}},
  rarity = 1,
  atlas = 'RedditJokers',
  pos = {x=6,y=1},
  cost = 3,
  loc_vars = function(self,info_queue,card)
    return {vars = {card.ability.chips, card.ability.chips_gain}}
  end,
  calculate = function(self,card,context)
    if context.joker_main then
      return {
        chip_mod = card.ability.chips,
        message = localize { type = 'variable', key = 'a_chips', vars = { card.ability.chips } }
      }
    end
    if context.before and not card.ability.hands[G.GAME.last_hand_played] then
      card.ability.hands[G.GAME.last_hand_played] = true
      card.ability.chips = card.ability.chips + card.ability.chips_gain
      card_eval_status_text(
        card,
        'extra',
        nil, nil, nil,
        {message = localize('k_upgrade_ex'), colour = G.C.CHIPS}
      )
    end
    if context.end_of_round and card.ability.chips > 0 then
      card.ability.chips = 0
      card.ability.hands  = {
        ["Flush Five"] = false,
        ["Flush House"] = false,
        ["Five of a Kind"] = false,
        ["Straight Flush"] = false,
        ["Four of a Kind"] = false,
        ["Full House"] = false,
        ["Flush"] = false,
        ["Straight"] = false,
        ["Three of a Kind"] = false,
        ["Two Pair"] = false,
        ["Pair"] = false,
        ["High Card"] = false
      }
      return {
        message = localize('k_reset'),
        colour = G.C.BLUE
      }
    end
  end
}

----------------------------------------------
------------MOD CODE END----------------------
