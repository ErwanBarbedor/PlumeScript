return {
    files = {
        ["test.plume"] = [[]]
    },
    commands = {
        "./plume test.plume  --no-cache"
    },
    expected = {
        output = "Executed with success."
    }
}