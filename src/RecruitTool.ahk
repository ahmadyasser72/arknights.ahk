#Requires AutoHotkey v2.0

#Include Helper.ahk

#Include <OCR>

class RecruitToolConst {
  statiC MAX_RARITY := 6
  static MIN_RARITY := 4

  static TAGS_TOP_LEFT_XY := [
    [410, 390], [585, 390], [765, 390],
    [410, 465], [585, 465],
  ]

  static TAG_HEIGHT := 45
  static TAG_WIDTH := 145
}

RecruitTool() {
  tags := ReadRecruitTags()
  matches := MatchRecruitTags(tags)

  if matches.Length == 0
    return

  operator_map := Map()
  for match in matches {
    combination_tags := []
    for idx in match.combination
      combination_tags.Push tags[idx]

    for idx, operator in match.operators {
      others := []
      for other_idx, other_operator in match.operators
        if other_idx != idx
          others.Push other_operator.ToString()

      operator_map.Set(
        operator.ToString(), { combination: combination_tags, others: others }
      )
    }
  }

  for operator_name in operator_map {
    value := operator_map.Delete(operator_name)
    operator_map.Set(
      Format("{} ({:.0f}%)", operator_name, 1 / (value.others.Length + 1) * 100),
      value
    )
  }

  CompareOperator(a, b, *) {
    a := operator_map[a]
    b := operator_map[b]

    ; sort operator with higher chance first
    rate_delta := a.others.Length - b.others.length
    if rate_delta != 0
      return rate_delta
    ; then group them if their combination is the same
    else if a.combination != b.combination
      return -1
    else
      return 0
  }

  recruit_tool_gui := Gui("AlwaysOnTop -MinimizeBox", "RecruitTool")

  recruit_tool_gui.AddText(, "Operator list")
  gui_operator_dropdown := recruit_tool_gui.AddDropDownList(
    'Choose1',
    StrSplit(
      Sort(
        ArrayJoin([operator_map*], '|'),
        'D|', CompareOperator
      ), '|'
    )
  )

  recruit_tool_gui.AddText(, "Tags combination")
  gui_operator_combination := recruit_tool_gui.AddListBox('r3')
  UpdateGuiOperatorCombination(*) {
    gui_operator_combination.Delete()
    gui_operator_combination.Add(operator_map[gui_operator_dropdown.Text].combination)
  }
  gui_operator_dropdown.OnEvent('Change', UpdateGuiOperatorCombination)
  UpdateGuiOperatorCombination()

  recruit_tool_gui.AddText("ym", "Other possible operators")
  gui_other_possible_operators := recruit_tool_gui.AddListBox('r6')
  UpdateOtherPossibleOperators(*) {
    gui_other_possible_operators.Delete()
    gui_other_possible_operators.Add(operator_map[gui_operator_dropdown.Text].others)
  }
  gui_operator_dropdown.OnEvent('Change', UpdateOtherPossibleOperators)
  UpdateOtherPossibleOperators()

  recruit_tool_gui.Show()
}

MatchRecruitTags(tags) {
  matches := []

combination_loop:
  for combination_idx in RecruitToolData.combinations {
    combination_tags := []
    for idx in combination_idx
      combination_tags.Push tags[idx]

    has_robot := ArrayIncludes(combination_tags, 'robot')

    combination_operators := []
    combination_min_rarity := RecruitToolConst.MAX_RARITY
    for operator in RecruitToolData.operators
      if operator.MatchCombination(combination_tags) {
        if (
          operator.rarity < RecruitToolConst.MIN_RARITY
          && operator.rarity != 1
        ) {
          ; skip this combination if there's
          ; an operator with rarity below the minimum
          continue combination_loop
        } else if (
          operator.rarity <= combination_min_rarity
          || (has_robot && operator.rarity == 1)
        ) {
          combination_min_rarity := operator.rarity
          combination_operators.Push operator
        }
      }

    if combination_operators.Length > 0 {
      matches.Push({ combination: combination_idx, operators: combination_operators })
    }
  }

  return matches
}

ReadRecruitTags() {
  tags := []
  for xy in RecruitToolConst.TAGS_TOP_LEFT_XY {
    tag := OCR.FromRect(
      xy[1], xy[2],
      RecruitToolConst.TAG_WIDTH, RecruitToolConst.TAG_HEIGHT,
      'en-US', 2.5
    ).Text
    ; alter the tag a little for consistency with aceship data
    tag := StrReplace(tag, '-', ' ')
    tag := StrLower(tag)
    tags.Push tag
  }

  return tags
}

class Operator {
  __New(name, rarity, tags) {
    this.name := name
    this.rarity := rarity
    this.tags := tags
  }

  MatchCombination(tag_combination) {
    if this.rarity == 6 ; 6★ needs top operator tag
      && !ArrayIncludes(tag_combination, "top operator")
      return false

    for tag in tag_combination
      if !ArrayIncludes(this.tags, tag)
        return false

    return true
  }

  ToString() {
    return Format("{}★ - {}", this.rarity, this.name)
  }
}

; --- everything below is automatically generated by scripts/fetch_recruit_data.py

; Last updated: 2024-06-04
class RecruitToolData {
  static combinations := [
    [1], [2], [3], [4], [5],
    [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5], [3, 4], [3, 5], [4, 5],
    [1, 2, 3], [1, 2, 4], [1, 2, 5], [1, 3, 4], [1, 3, 5], [1, 4, 5], [2, 3, 4], [2, 3, 5], [2, 4, 5], [3, 4, 5],
  ]

  static operators := [
    Operator('"Justice Knight"', 1, ['sniper', 'robot', 'ranged', 'robot', 'support']),
    Operator('Castle-3', 1, ['guard', 'robot', 'melee', 'robot', 'support']),
    Operator('Friston-3', 1, ['defender', 'robot', 'melee', 'robot', 'defense']),
    Operator('Lancet-2', 1, ['medic', 'robot', 'ranged', 'robot', 'healing']),
    Operator('Thermal-EX', 1, ['specialist', 'robot', 'melee', 'robot', 'nuker']),
    Operator('12F', 2, ['caster', 'ranged', 'starter']),
    Operator('Durin', 2, ['caster', 'ranged', 'starter']),
    Operator('Noir Corne', 2, ['defender', 'melee', 'starter']),
    Operator('Rangers', 2, ['sniper', 'ranged', 'starter']),
    Operator('Yato', 2, ['vanguard', 'melee', 'starter']),
    Operator('Adnachiel', 3, ['sniper', 'ranged', 'dps']),
    Operator('Ansel', 3, ['medic', 'ranged', 'healing']),
    Operator('Beagle', 3, ['defender', 'melee', 'defense']),
    Operator('Catapult', 3, ['sniper', 'ranged', 'aoe']),
    Operator('Fang', 3, ['vanguard', 'melee', 'dp recovery']),
    Operator('Hibiscus', 3, ['medic', 'ranged', 'healing']),
    Operator('Kroos', 3, ['sniper', 'ranged', 'dps']),
    Operator('Lava', 3, ['caster', 'ranged', 'aoe']),
    Operator('Melantha', 3, ['guard', 'melee', 'dps', 'survival']),
    Operator('Midnight', 3, ['guard', 'melee', 'dps']),
    Operator('Orchid', 3, ['supporter', 'ranged', 'slow']),
    Operator('Plume', 3, ['vanguard', 'melee', 'dps', 'dp recovery']),
    Operator('Popukar', 3, ['guard', 'melee', 'aoe', 'survival']),
    Operator('Spot', 3, ['defender', 'melee', 'defense', 'healing']),
    Operator('Steward', 3, ['caster', 'ranged', 'dps']),
    Operator('Vanilla', 3, ['vanguard', 'melee', 'dp recovery']),
    Operator('Aciddrop', 4, ['sniper', 'ranged', 'dps']),
    Operator('Ambriel', 4, ['sniper', 'ranged', 'dps', 'slow']),
    Operator('Beehunter', 4, ['guard', 'melee', 'dps']),
    Operator('Click', 4, ['caster', 'ranged', 'dps', 'crowd control']),
    Operator('Cuora', 4, ['defender', 'melee', 'defense']),
    Operator('Cutter', 4, ['guard', 'melee', 'nuker', 'dps']),
    Operator('Dobermann', 4, ['guard', 'melee', 'dps', 'support']),
    Operator('Earthspirit', 4, ['supporter', 'ranged', 'slow']),
    Operator('Estelle', 4, ['guard', 'melee', 'aoe', 'survival']),
    Operator('Frostleaf', 4, ['guard', 'melee', 'slow', 'dps']),
    Operator('Gitano', 4, ['caster', 'ranged', 'aoe']),
    Operator('Gravel', 4, ['specialist', 'melee', 'fast redeploy', 'defense']),
    Operator('Greyy', 4, ['caster', 'ranged', 'aoe', 'slow']),
    Operator('Gum', 4, ['defender', 'melee', 'defense', 'healing']),
    Operator('Haze', 4, ['caster', 'ranged', 'dps', 'debuff']),
    Operator('Jaye', 4, ['specialist', 'melee', 'fast redeploy', 'dps']),
    Operator('Jessica', 4, ['sniper', 'ranged', 'dps', 'survival']),
    Operator('Matoimaru', 4, ['guard', 'melee', 'survival', 'dps']),
    Operator('Matterhorn', 4, ['defender', 'melee', 'defense']),
    Operator('May', 4, ['sniper', 'ranged', 'dps', 'slow']),
    Operator('Meteor', 4, ['sniper', 'ranged', 'dps', 'debuff']),
    Operator('Mousse', 4, ['guard', 'melee', 'dps']),
    Operator('Myrrh', 4, ['medic', 'ranged', 'healing']),
    Operator('Myrtle', 4, ['vanguard', 'melee', 'dp recovery', 'healing']),
    Operator('Perfumer', 4, ['medic', 'ranged', 'healing']),
    Operator('Podenco', 4, ['supporter', 'ranged', 'slow', 'healing']),
    Operator('Purestream', 4, ['medic', 'ranged', 'healing', 'support']),
    Operator('Rope', 4, ['specialist', 'melee', 'shift']),
    Operator('Scavenger', 4, ['vanguard', 'melee', 'dp recovery', 'dps']),
    Operator('Shaw', 4, ['specialist', 'melee', 'shift']),
    Operator('ShiraYuki', 4, ['sniper', 'ranged', 'aoe', 'slow']),
    Operator('Sussurro', 4, ['medic', 'ranged', 'healing']),
    Operator('Utage', 4, ['guard', 'melee', 'dps', 'survival']),
    Operator('Vermeil', 4, ['sniper', 'ranged', 'dps']),
    Operator('Vigna', 4, ['vanguard', 'melee', 'dps', 'dp recovery']),
    Operator('Andreana', 5, ['sniper', 'senior operator', 'ranged', 'dps', 'slow']),
    Operator('Asbestos', 5, ['defender', 'senior operator', 'melee', 'defense', 'dps']),
    Operator('Astesia', 5, ['guard', 'senior operator', 'melee', 'dps', 'defense']),
    Operator('Ayerscarpe', 5, ['guard', 'senior operator', 'melee', 'dps', 'aoe']),
    Operator('Beeswax', 5, ['caster', 'senior operator', 'ranged', 'aoe', 'defense']),
    Operator('Blue Poison', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Broca', 5, ['guard', 'senior operator', 'melee', 'aoe', 'survival']),
    Operator('Chiave', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'dps']),
    Operator('Cliffheart', 5, ['specialist', 'senior operator', 'melee', 'shift', 'dps']),
    Operator('Croissant', 5, ['defender', 'senior operator', 'melee', 'defense', 'shift']),
    Operator('Elysium', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'support']),
    Operator('Executor', 5, ['sniper', 'senior operator', 'ranged', 'aoe']),
    Operator('FEater', 5, ['specialist', 'senior operator', 'melee', 'shift', 'slow']),
    Operator('Firewatch', 5, ['sniper', 'senior operator', 'ranged', 'dps', 'nuker']),
    Operator('Flint', 5, ['guard', 'senior operator', 'melee', 'dps']),
    Operator('Glaucus', 5, ['supporter', 'senior operator', 'ranged', 'slow', 'crowd control']),
    Operator('GreyThroat', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Hung', 5, ['defender', 'senior operator', 'melee', 'defense', 'healing']),
    Operator('Indra', 5, ['guard', 'senior operator', 'melee', 'dps', 'survival']),
    Operator('Istina', 5, ['supporter', 'senior operator', 'ranged', 'slow', 'dps']),
    Operator('Leizi', 5, ['caster', 'senior operator', 'ranged', 'dps']),
    Operator('Leonhardt', 5, ['caster', 'senior operator', 'ranged', 'aoe', 'nuker']),
    Operator('Liskarm', 5, ['defender', 'senior operator', 'melee', 'defense', 'dps']),
    Operator('Manticore', 5, ['specialist', 'senior operator', 'melee', 'dps', 'survival']),
    Operator('Mayer', 5, ['supporter', 'senior operator', 'ranged', 'summon', 'crowd control']),
    Operator('Meteorite', 5, ['sniper', 'senior operator', 'ranged', 'aoe', 'debuff']),
    Operator('Nearl', 5, ['defender', 'senior operator', 'melee', 'defense', 'healing']),
    Operator('Nightmare', 5, ['caster', 'senior operator', 'ranged', 'dps', 'healing', 'slow']),
    Operator('Platinum', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Pramanix', 5, ['supporter', 'senior operator', 'ranged', 'debuff']),
    Operator('Projekt Red', 5, ['specialist', 'senior operator', 'melee', 'fast redeploy', 'crowd control']),
    Operator('Provence', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Ptilopsis', 5, ['medic', 'senior operator', 'ranged', 'healing', 'support']),
    Operator('Reed', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'dps']),
    Operator('Sesa', 5, ['sniper', 'senior operator', 'ranged', 'aoe', 'debuff']),
    Operator('Shamare', 5, ['supporter', 'senior operator', 'ranged', 'debuff']),
    Operator('Silence', 5, ['medic', 'senior operator', 'ranged', 'healing']),
    Operator('Specter', 5, ['guard', 'senior operator', 'melee', 'aoe', 'survival']),
    Operator('Swire', 5, ['guard', 'senior operator', 'melee', 'dps', 'support']),
    Operator('Texas', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'crowd control']),
    Operator('Tsukinogi', 5, ['supporter', 'senior operator', 'ranged', 'support', 'survival']),
    Operator('Vulcan', 5, ['defender', 'senior operator', 'melee', 'survival', 'defense', 'dps']),
    Operator('Waai Fu', 5, ['specialist', 'senior operator', 'melee', 'fast redeploy', 'debuff']),
    Operator('Warfarin', 5, ['medic', 'senior operator', 'ranged', 'healing', 'support']),
    Operator('Zima', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'support']),
    Operator('Aak', 6, ['specialist', 'top operator', 'ranged', 'support', 'dps']),
    Operator('Bagpipe', 6, ['vanguard', 'top operator', 'melee', 'dp recovery', 'dps']),
    Operator('Blaze', 6, ['guard', 'top operator', 'melee', 'dps', 'survival']),
    Operator('Ceobe', 6, ['caster', 'top operator', 'ranged', 'dps', 'crowd control']),
    Operator("Ch'en", 6, ['guard', 'top operator', 'melee', 'nuker', 'dps']),
    Operator('Eunectes', 6, ['defender', 'top operator', 'melee', 'dps', 'survival', 'defense']),
    Operator('Exusiai', 6, ['sniper', 'top operator', 'ranged', 'dps']),
    Operator('Hellagur', 6, ['guard', 'top operator', 'melee', 'dps', 'survival']),
    Operator('Hoshiguma', 6, ['defender', 'top operator', 'melee', 'defense', 'dps']),
    Operator('Ifrit', 6, ['caster', 'top operator', 'ranged', 'aoe', 'debuff']),
    Operator('Magallan', 6, ['supporter', 'top operator', 'ranged', 'support', 'slow', 'dps']),
    Operator('Mostima', 6, ['caster', 'top operator', 'ranged', 'aoe', 'support', 'crowd control']),
    Operator('Nightingale', 6, ['medic', 'top operator', 'ranged', 'healing', 'support']),
    Operator('Phantom', 6, ['specialist', 'top operator', 'melee', 'fast redeploy', 'crowd control', 'dps']),
    Operator('Rosa', 6, ['sniper', 'top operator', 'ranged', 'dps', 'crowd control']),
    Operator('Saria', 6, ['defender', 'top operator', 'melee', 'defense', 'healing', 'support']),
    Operator('Schwarz', 6, ['sniper', 'top operator', 'ranged', 'dps']),
    Operator('Shining', 6, ['medic', 'top operator', 'ranged', 'healing', 'support']),
    Operator('Siege', 6, ['vanguard', 'top operator', 'melee', 'dp recovery', 'dps']),
    Operator('SilverAsh', 6, ['guard', 'top operator', 'melee', 'dps', 'support']),
    Operator('Skadi', 6, ['guard', 'top operator', 'melee', 'dps', 'survival']),
    Operator('Suzuran', 6, ['supporter', 'top operator', 'ranged', 'slow', 'support', 'dps']),
    Operator('Thorns', 6, ['guard', 'top operator', 'melee', 'dps', 'defense']),
    Operator('Weedy', 6, ['specialist', 'top operator', 'melee', 'shift', 'dps', 'crowd control']),
  ]
}
