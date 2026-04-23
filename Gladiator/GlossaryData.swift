//
//  GlossaryData.swift
//  Gladiator
//

import Foundation

struct GlossaryTerm: Identifiable {
    let id: String
    let name: String
    let definition: String
    let children: [GlossaryChild]
    let seeAlso: [String]
}

struct GlossaryChild: Identifiable {
    let id: String
    let name: String
    let definition: String
}

enum GlossaryData {
    static let allTerms: [GlossaryTerm] = [
        GlossaryTerm(
            id: "correlation",
            name: "Correlation",
            definition: "A statistical measure that describes the strength and direction of a relationship between two metrics. Correlation values range from -1.0 (perfect inverse relationship) to +1.0 (perfect direct relationship), with 0 indicating no relationship.",
            children: [
                GlossaryChild(
                    id: "pearson",
                    name: "Pearson Correlation Coefficient (r)",
                    definition: "The specific formula used to calculate correlation in Gladiator. It measures the linear relationship between two sets of values. An r value close to +1 or -1 indicates a strong linear relationship, while a value near 0 suggests little to no linear relationship."
                ),
                GlossaryChild(
                    id: "confidence",
                    name: "Confidence Level",
                    definition: "An indicator of how reliable a correlation result is based on sample size. Low Confidence (5–10 sessions) means the result may shift significantly as more data is collected. Moderate Confidence (11–30 sessions) is more stable. High Confidence (31+ sessions) provides the most reliable results."
                )
            ],
            seeAlso: ["Scatter Plot", "Trend Analysis"]
        ),
        GlossaryTerm(
            id: "correlation-matrix",
            name: "Correlation Matrix",
            definition: "A grid that shows the Pearson correlation coefficient between every pair of plottable metrics at once. Rows and columns both list your Number and Time metrics, and each cell is color-coded so strong relationships jump out at a glance.",
            children: [
                GlossaryChild(
                    id: "heat-map",
                    name: "Heat Map",
                    definition: "A color-coded visualization where each cell's color encodes the strength and direction of a value. In the Correlation Matrix, warm colors (orange) indicate positive relationships, cool colors (blue) indicate negative relationships, and neutral greys indicate weak or no relationship."
                )
            ],
            seeAlso: ["Correlation", "Scatter Plot"]
        ),
        GlossaryTerm(
            id: "trend-analysis",
            name: "Trend Analysis",
            definition: "A tool for tracking how a metric changes over time. It plots individual session values chronologically and overlays a smoothed line to reveal the overall direction of change, filtering out noise from session-to-session variation.",
            children: [
                GlossaryChild(
                    id: "moving-average",
                    name: "Moving Average",
                    definition: "A calculation that smooths out short-term fluctuations by averaging a fixed number of recent sessions (the window size). A 5-session moving average, for example, shows the average of the most recent 5 values at each point, making it easier to see the underlying trend."
                ),
                GlossaryChild(
                    id: "trend-direction",
                    name: "Trend Direction",
                    definition: "An indicator showing whether a metric is Improving, Declining, or Stable based on the slope of the moving average. For time-based metrics like lap time, a decrease is considered an improvement. For number-based metrics, an increase is considered an improvement by default."
                )
            ],
            seeAlso: ["Correlation", "Personal Best"]
        ),
        GlossaryTerm(
            id: "session-comparison",
            name: "Session Comparison",
            definition: "A tool for comparing metric values side by side between two sessions or two time periods. It highlights which side performed better for each metric, giving a clear picture of progress or regression.",
            children: [
                GlossaryChild(
                    id: "session-average",
                    name: "Session Average",
                    definition: "When comparing time periods (year vs year, month vs month, or custom ranges), each metric is shown as the arithmetic mean of all recorded values within that period. This provides a representative single value for comparison rather than showing every individual session."
                )
            ],
            seeAlso: ["Session Type", "Custom Metric"]
        ),
        GlossaryTerm(
            id: "personal-best",
            name: "Personal Best",
            definition: "The all-time best recorded value for a given metric across all sessions. For time-based metrics, the best is the lowest value (fastest time). For number-based metrics, the best is the highest value. Each personal best shows which session and date it was achieved.",
            children: [],
            seeAlso: ["Trend Analysis", "Custom Metric"]
        ),
        GlossaryTerm(
            id: "session-type",
            name: "Session Type",
            definition: "A classification applied to each recorded session: Practice, Qualifying, or Race. Session types help organize and filter your data, and can be used to compare performance across different types of on-track activity.",
            children: [],
            seeAlso: ["Session Comparison"]
        ),
        GlossaryTerm(
            id: "custom-metric",
            name: "Custom Metric",
            definition: "A user-defined data field for tracking specific performance or setup values. Each metric has a type — Number (e.g. tire pressure, fuel load), Text (e.g. tire compound), or Time (e.g. lap time, sector time). Metrics can be added, edited, reordered, and removed in Settings without affecting existing saved sessions.",
            children: [],
            seeAlso: ["Personal Best", "Scatter Plot"]
        ),
        GlossaryTerm(
            id: "metric-log",
            name: "Metric Log",
            definition: "A table view that lists every session containing a recorded value for a chosen metric. Each row shows the session date, track, vehicle, and the recorded value. Rows can be sorted by date or by value to surface patterns in your data without switching tools.",
            children: [],
            seeAlso: ["Custom Metric", "Personal Best", "Scatter Plot"]
        ),
        GlossaryTerm(
            id: "scatter-plot",
            name: "Scatter Plot",
            definition: "A graph that plots two metrics against each other, with one on the X axis and one on the Y axis. Each data point represents a session. Scatter plots are useful for visually identifying relationships or clusters in your data — for example, whether higher tire pressure tends to correlate with faster lap times.",
            children: [],
            seeAlso: ["Correlation", "Custom Metric"]
        ),
        GlossaryTerm(
            id: "performance-predictor",
            name: "Performance Predictor",
            definition: "A tool that builds a predictive model from your session data. You choose one outcome metric (what you want to predict) and up to five predictor metrics (what might influence it). The model estimates how much of the variation in the outcome can be explained by the predictors together, and ranks each predictor by its relative importance.",
            children: [
                GlossaryChild(
                    id: "r-squared",
                    name: "R-Squared",
                    definition: "A value between 0 and 1 (shown as a percentage) that measures how well the selected predictors, taken together, explain variation in the outcome. 0% means the predictors explain none of the variation; 100% means they explain all of it. The Performance Predictor displays the adjusted form of R-Squared rather than raw R-Squared — see Predictive Power."
                ),
                GlossaryChild(
                    id: "multiple-linear-regression",
                    name: "Multiple Linear Regression",
                    definition: "The statistical method used to fit the predictive model. It finds the combination of predictor weights that best matches the outcome across all analyzed sessions, using ordinary least squares."
                ),
                GlossaryChild(
                    id: "predictor-contribution",
                    name: "Predictor Contribution",
                    definition: "Each predictor's share of the model's total importance, expressed as a percentage. Contributions are derived from standardized regression coefficients so metrics on different scales (for example tire pressure in PSI vs lap time in seconds) can be compared fairly."
                )
            ],
            seeAlso: ["Correlation", "Correlation Matrix", "Predictive Power", "Standard Deviation"]
        ),
        GlossaryTerm(
            id: "predictive-power",
            name: "Predictive Power",
            definition: "The Performance Predictor's headline score, displayed as a percentage. It uses Adjusted R-Squared, a corrected version of R-Squared. The adjustment discounts the score for each additional predictor in the model, preventing a misleadingly high number from simply stacking more variables. A lower Predictive Power does not mean the tool is broken — it means untracked factors (weather, tire temperature, driver state, unlogged setup changes) also influence the outcome. Tracking more of those factors as metrics raises the ceiling over time.",
            children: [
                GlossaryChild(
                    id: "adjusted-r-squared",
                    name: "Adjusted R-Squared",
                    definition: "A correction applied to R-Squared that discounts the score for each additional predictor. Raw R-Squared never decreases when you add more predictors — even noise can nudge it upward. Adjusted R-Squared removes that inflation so the number reflects real predictive signal rather than model complexity. Formula: 1 - (1 - R²) × (n - 1) / (n - k - 1), where n is the number of sessions and k is the number of predictors."
                )
            ],
            seeAlso: ["Performance Predictor", "Correlation"]
        ),
        GlossaryTerm(
            id: "standard-deviation",
            name: "Standard Deviation",
            definition: "A measure of how spread out your values are from the average. A low standard deviation means your results are consistent and clustered near the mean. A high standard deviation means there is more variation between sessions. It is commonly used to evaluate consistency in performance.",
            children: [],
            seeAlso: ["Correlation", "Trend Analysis"]
        )
    ]

    static func find(byName name: String) -> GlossaryTerm? {
        allTerms.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    static func search(query: String) -> [GlossaryTerm] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return allTerms }
        return allTerms.filter { term in
            term.name.lowercased().contains(q)
            || term.definition.lowercased().contains(q)
            || term.children.contains { child in
                child.name.lowercased().contains(q)
                || child.definition.lowercased().contains(q)
            }
        }
    }

    static func matchingChildIDs(in term: GlossaryTerm, query: String) -> Set<String> {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return Set(term.children.filter { child in
            child.name.lowercased().contains(q)
            || child.definition.lowercased().contains(q)
        }.map(\.id))
    }
}
