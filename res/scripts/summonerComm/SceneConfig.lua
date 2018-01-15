local SceneManager = require("common.SceneManager")

SceneManager.Scene = {
    SceneLogin = 1,
    SceneHall = 2,
    SceneWorld = 3,
    SceneBattle = 4,
    SceneUnion = 5,
    ScenePvp = 6,
    SceneTowerTrial = 7,
    SceneReplayBattle = 8,
}

SceneManager.SceneConfig = {
    SceneLogin = { loadingView = false, cleanup = true},
    SceneHall = { loadingView = true, cleanup = true },
    SceneWorld = { loadingView = true, cleanup = true },
    SceneBattle = { loadingView = true, cleanup = true },
    SceneUnion = { loadingView = true, cleanup = true },
    ScenePvp = { loadingView = false, cleanup = true },
    SceneTowerTrial = { loadingView = true, cleanup = true },
    SceneReplayBattle = { loadingView = true, cleanup = true },
}
