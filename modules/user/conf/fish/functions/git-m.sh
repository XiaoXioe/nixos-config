# Git Conventional Commits Functions
function gcfeat
    git commit -m "feat: $argv"
end

function gcfix
    git commit -m "fix: $argv"
end

function gcchore
    git commit -m "chore: $argv"
end

function gcdocs
    git commit -m "docs: $argv"
end

function gcstyle
    git commit -m "style: $argv"
end

function gcref
    git commit -m "refactor: $argv"
end

function gctest
    git commit -m "test: $argv"
end
