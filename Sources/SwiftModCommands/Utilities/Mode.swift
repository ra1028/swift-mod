import ArgumentParser

public enum Mode: String, ExpressibleByArgument {
    case modify
    case dryRun = "dry-run"
    case check
}
