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
                    id: "data-sufficiency",
                    name: "Data Sufficiency",
                    definition: "A five-tier rating — Bad, Poor, Fair, Good, Excellent — indicating how well your sample size supports a correlation result. Thresholds are shared with Performance Predictor so a given sample size carries the same meaning across both tools. 10-19 sessions → Bad, results are unlikely to be reliable and could be skewed by a few unusual sessions. 20-29 → Poor, an early indication only — not yet actionable. 30-49 → Fair, a reasonable foundation, directionally useful but may shift. 50-99 → Good, a solid foundation, reliable enough to act on. 100+ → Excellent, meets the ideal threshold and can be acted on with confidence. Below 10 sessions with both metrics recorded, Correlation Analysis does not produce a result."
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
            children: [
                GlossaryChild(
                    id: "car-zone",
                    name: "Car Zone",
                    definition: "A region of the visual race car interface in Add and Edit Session that groups related metrics. Zones are FL Tire, FR Tire, BL Tire, BR Tire, Engine, Cockpit, Front, Rear, and General. Each metric is assigned to one zone in the Add or Edit Metric form (default General). Tapping a zone on the car opens a focused entry sheet listing only that zone's metrics. Zones with assigned metrics glow orange and display a filled-out indicator (e.g. 2/3); zones with no assigned metrics remain visible but are not tappable. General-zone metrics appear in a connected list below the car alongside session details. Zone is purely an organisational layer — it does not affect analytics, persistence, or any per-track calculations."
                )
            ],
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
                    id: "predictive-power",
                    name: "Predictive Power",
                    definition: "The headline percentage shown in the Performance Predictor result. It is calculated as Adjusted R-Squared, a corrected form of R-Squared (the coefficient of determination) that discounts the score for each additional predictor. The number answers: of all the variation in your outcome across sessions, how much is explained by your selected predictors together? 0% means the predictors explain none of the variation; 100% means they explain all of it. The adjustment prevents a misleadingly high score from simply stacking more predictors, so a higher Predictive Power reflects a stronger, more parsimonious relationship. A lower value does not mean the tool is broken — it means untracked factors also influence the outcome."
                ),
                GlossaryChild(
                    id: "data-sufficiency",
                    name: "Data Sufficiency",
                    definition: "A five-tier rating — Bad, Poor, Fair, Good, Excellent — indicating how well your sample size supports the model. It is based on sessions per predictor (total qualifying sessions divided by the number of predictors). The lower thresholds are drawn from published rules of thumb: a minimum of 10 sessions per predictor (Stevens 1992) and a recommended threshold of 20 per predictor (Hair et al 2010). The upper thresholds (50 and 100 per predictor) reflect broader statistical consensus on what constitutes well-supported and ideally-supported multiple regression. 10-19 per predictor → Bad, results are unlikely to be reliable and could be skewed by a few unusual sessions. 20-29 → Poor, an early indication only — not yet actionable. 30-49 → Fair, a reasonable foundation, directionally useful but may shift. 50-99 → Good, a solid foundation, reliable enough to act on. 100+ → Excellent, meets the ideal threshold and can be acted on with confidence."
                ),
                GlossaryChild(
                    id: "model-reliability",
                    name: "Model Reliability",
                    definition: "The degree to which a predictive result can be trusted to generalize beyond the sessions it was built from. Reliability scales primarily with sessions per predictor: more sessions mean each coefficient is less influenced by any single session, and the Predictive Power score is less likely to shift substantially when new data is added. A lower Predictive Power built on many sessions is often more trustworthy than a higher Predictive Power built on few — the latter can easily be inflated by noise, outliers, or lucky combinations within a small sample."
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
            seeAlso: ["Correlation", "Correlation Matrix", "Standard Deviation"]
        ),
        GlossaryTerm(
            id: "race-engineer",
            name: "Race Engineer",
            definition: "A tool that automatically searches every combination of your Number and Time metrics to find the set that best predicts a chosen outcome, then turns that winning model into actionable setup guidance. You pick the outcome (for example Race Time or Tire Temperature) and Race Engineer does the rest: it fits thousands of candidate models using multiple linear regression, keeps the one with the highest Model Predictive Power, and presents its Metric Contributors, their direction of influence, and Setup Recommendations drawn from your fastest sessions. Unlike Performance Predictor, where you choose the predictors yourself, Race Engineer selects them for you.",
            children: [
                GlossaryChild(
                    id: "best-subset-selection",
                    name: "Best Subset Selection",
                    definition: "The search procedure Race Engineer uses to pick which metrics enter the model. It exhaustively fits every combination of up to 15 of your plottable metrics — with 15 candidates that is 32,767 separate models — and keeps the combination with the highest Model Predictive Power. Each candidate model is fit with the same multiple linear regression (ordinary least squares) used by Performance Predictor, so both tools agree on what a given combination's predictive power is; the difference is that Race Engineer chooses the combination automatically rather than asking you to. The 15-metric cap keeps the search tractable and reflects that typical session counts cannot reliably support more predictors than that anyway."
                ),
                GlossaryChild(
                    id: "model-predictive-power",
                    name: "Model Predictive Power",
                    definition: "The headline percentage shown at the top of the Race Engineer result, and the value the subset search optimizes for. It is calculated as Adjusted R-Squared — a corrected form of R-Squared (the coefficient of determination) that discounts the score for each additional predictor so a model cannot look better simply by adding more metrics. A 40% Model Predictive Power means the winning set of Metric Contributors jointly explains about 40% of the session-to-session variation in your chosen outcome, with the remaining 60% driven by factors outside your current tracked data. A lower value does not mean the tool is broken — it means untracked factors also influence the outcome."
                ),
                GlossaryChild(
                    id: "metric-contributors",
                    name: "Metric Contributors",
                    definition: "The metrics Race Engineer selected for the winning model, listed in the METRIC CONTRIBUTORS section with a count next to the section title. Each contributor shows a Contribution Share, a Direction of Influence, a per-unit effect estimate, and the observed range across your sessions. The first contributor listed is the largest single lever on your outcome in this dataset; subsequent contributors are secondary levers but still carry measurable weight in the model."
                ),
                GlossaryChild(
                    id: "contribution-share",
                    name: "Contribution Share",
                    definition: "The percentage displayed next to each Metric Contributor's name, representing its share of the model's total explanatory power. Shares are derived from standardized regression coefficients so metrics on different scales — tire pressure in PSI, lap time in seconds, fuel in gallons — can be compared fairly. Multiplying a contributor's share by the overall Model Predictive Power gives the approximate portion of outcome variation attributable to that metric alone, assuming the others in the model are held fixed."
                ),
                GlossaryChild(
                    id: "direction-of-influence",
                    name: "Direction of Influence",
                    definition: "The arrow and sentence shown beneath each Metric Contributor indicating whether higher or lower values of that metric are associated with a better outcome in your data. It is derived from the sign of the predictor's standardized regression coefficient combined with the outcome type: for Time outcomes (where lower is better) a negative coefficient means higher values of the predictor are associated with faster times, while for Number outcomes (where higher is better) the relationship is reversed. When the coefficient is effectively zero the direction is shown as uncertain — the model found no reliable sign for that predictor in your current data."
                ),
                GlossaryChild(
                    id: "setup-recommendations",
                    name: "Setup Recommendations",
                    definition: "Actionable hypotheses generated from the winning model, one per Metric Contributor. When a contributor has a clear direction and its values in your fastest sessions span a distinctive range, Race Engineer recommends targeting that range. When the direction is clear but the range is not discriminating, it suggests raising or lowering from your current session average based on the coefficient's sign. When a metric has not varied meaningfully across your sessions, it asks you to deliberately vary that value in future sessions so the model has something to learn from. These are testing hypotheses, not guaranteed outcomes — they are intended to be tried on track one change at a time and tracked with Correlation or Trend Analysis."
                ),
                GlossaryChild(
                    id: "data-sufficiency",
                    name: "Data Sufficiency",
                    definition: "A five-tier rating — Bad, Poor, Fair, Good, Excellent — indicating how well your sample size supports the winning model. Thresholds match Performance Predictor and are based on sessions per predictor (total qualifying sessions divided by the number of metrics in the winning combination): 10-19 per predictor → Bad, 20-29 → Poor, 30-49 → Fair, 50-99 → Good, 100+ → Excellent. At lower sufficiency levels the winning combination is more likely to change as new sessions are added, because a smaller sample lets noise or a few unusual sessions tip one combination above another."
                )
            ],
            seeAlso: ["Performance Predictor", "Correlation", "Trend Analysis"]
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
