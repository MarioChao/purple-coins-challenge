--!strict

-- Types


---------- Types ----------

export type ChallengeModule = {
    getConfigs: () -> {
        _challengeId: string,
        showUIOnCharJoin: boolean,
        coinsFolder: Instance,
        isServerSided: boolean,
        defaultIsActivated: boolean,
        willResetOnDeath: boolean,
    },
    evaluatePlayerStateFromScore: (player: Player, score: number, totalScore: number) -> nil,
}

return {}
