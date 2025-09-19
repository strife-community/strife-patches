TeamTargetProperties = {}

-- Standard team target settings

local standard = {}

standard.assist = {}
standard.assist.priority = 50
standard.assist.attackers = 1
standard.assist.level = 1

standard.krytos = {}
standard.krytos.priority = 55
standard.krytos.attackers = 1
standard.krytos.level = 1

standard.cindara = {}
standard.cindara.priority = 55
standard.cindara.attackers = 4
standard.cindara.level = 9
standard.cindara.scriptvar = "bot_cindara"

standard.baldir = {}
standard.baldir.priority = 35
standard.baldir.attackers = 3
standard.baldir.level = 4

standard.base = {}
standard.base.priority = 60
standard.base.defend_priority = 100
standard.base.attackers = 4
standard.base.level = 9
standard.base.defend_level = 1

standard.generator = {}
standard.generator.priority = 50
standard.generator.defend_priority = 60
standard.generator.attackers = 4
standard.generator.level = 9
standard.generator.defend_level = 1

standard.tower2 = {}
standard.tower2.priority = 30
standard.tower2.defend_priority = 40
standard.tower2.attackers = 3
standard.tower2.level = 8
standard.tower2.defend_level = 1

standard.tower1 = {}
standard.tower1.priority = 10
standard.tower1.defend_priority = 20
standard.tower1.attackers = 1
standard.tower1.level = 7
standard.tower1.defend_level = 1

TeamTargetProperties.standard = standard

-- Beginner team target settings.  Effectively disables all team targets.

local tutorial = {}

tutorial.assist = {}
tutorial.assist.priority = 40
tutorial.assist.attackers = 1
tutorial.assist.level = 16

tutorial.krytos = {}
tutorial.krytos.priority = 55
tutorial.krytos.attackers = 1
tutorial.krytos.level = 1

tutorial.cindara = {}
tutorial.cindara.priority = 55
tutorial.cindara.attackers = 4
tutorial.cindara.level = 16

tutorial.baldir = {}
tutorial.baldir.priority = 35
tutorial.baldir.attackers = 3
tutorial.baldir.level = 16

tutorial.base = {}
tutorial.base.priority = 60
tutorial.base.defend_priority = 100
tutorial.base.attackers = 4
tutorial.base.level = 16
tutorial.base.defend_level = 5

tutorial.generator = {}
tutorial.generator.priority = 50
tutorial.generator.defend_priority = 60
tutorial.generator.attackers = 4
tutorial.generator.level = 16
tutorial.generator.defend_level = 5

tutorial.tower2 = {}
tutorial.tower2.priority = 30
tutorial.tower2.defend_priority = 40
tutorial.tower2.attackers = 3
tutorial.tower2.level = 16
tutorial.tower2.defend_level = 5

tutorial.tower1 = {}
tutorial.tower1.priority = 10
tutorial.tower1.defend_priority = 20
tutorial.tower1.attackers = 1
tutorial.tower1.level = 16
tutorial.base.defend_level = 5

TeamTargetProperties.tutorial = tutorial

-- Tutorial3 team target settings

local tutorial_3 = {}

tutorial_3.assist = {}
tutorial_3.assist.priority = 50
tutorial_3.assist.attackers = 1
tutorial_3.assist.level = 1

tutorial_3.krytos = {}
tutorial_3.krytos.priority = 55
tutorial_3.krytos.attackers = 1
tutorial_3.krytos.level = 1

tutorial_3.cindara = {}
tutorial_3.cindara.priority = 55
tutorial_3.cindara.attackers = 4
tutorial_3.cindara.level = 8
tutorial_3.cindara.scriptvar = "bot_cindara"

tutorial_3.baldir = {}
tutorial_3.baldir.priority = 35
tutorial_3.baldir.attackers = 3
tutorial_3.baldir.level = 4

tutorial_3.base = {}
tutorial_3.base.priority = 60
tutorial_3.base.defend_priority = 100
tutorial_3.base.attackers = 4
tutorial_3.base.level = 9
tutorial_3.base.defend_level = 5

tutorial_3.generator = {}
tutorial_3.generator.priority = 50
tutorial_3.generator.defend_priority = 60
tutorial_3.generator.attackers = 4
tutorial_3.generator.level = 9
tutorial_3.generator.defend_level = 5

tutorial_3.tower2 = {}
tutorial_3.tower2.priority = 30
tutorial_3.tower2.defend_priority = 40
tutorial_3.tower2.attackers = 3
tutorial_3.tower2.level = 8
tutorial_3.tower2.defend_level = 3

tutorial_3.tower1 = {}
tutorial_3.tower1.priority = 35
tutorial_3.tower1.defend_priority = 20
tutorial_3.tower1.attackers = 3
tutorial_3.tower1.level = 5
tutorial_3.tower1.defend_level = 2

TeamTargetProperties.tutorial_3 = tutorial_3

-- Easy team target settings.

local easy = {}

easy.assist = {}
easy.assist.priority = 40
easy.assist.attackers = 1
easy.assist.level = 1

easy.krytos = {}
easy.krytos.priority = 55
easy.krytos.attackers = 1
easy.krytos.level = 1

easy.cindara = {}
easy.cindara.priority = 55
easy.cindara.attackers = 4
easy.cindara.level = 10

easy.baldir = {}
easy.baldir.priority = 35
easy.baldir.attackers = 3
easy.baldir.level = 4

easy.base = {}
easy.base.priority = 60
easy.base.defend_priority = 100
easy.base.attackers = 4
easy.base.level = 10
easy.base.defend_level = 7

easy.generator = {}
easy.generator.priority = 50
easy.generator.defend_priority = 60
easy.generator.attackers = 4
easy.generator.level = 10
easy.generator.defend_level = 7

easy.tower2 = {}
easy.tower2.priority = 30
easy.tower2.defend_priority = 40
easy.tower2.attackers = 3
easy.tower2.level = 8
easy.tower2.defend_level = 5

easy.tower1 = {}
easy.tower1.priority = 10
easy.tower1.defend_priority = 20
easy.tower1.attackers = 1
easy.tower1.level = 7
easy.tower1.defend_level = 4

TeamTargetProperties.easy = easy

