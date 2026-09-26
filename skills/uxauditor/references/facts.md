# Dated facts for UX audits

Last reviewed: 2026-09-26

Standards and laws change. Cite a fact from this file with its date. When a line says "verify", check the source before you rely on it in a finding, and write "(verify current status)" next to the citation in the report if you cannot. Never cite a law as settled when this file marks it verify. Findings stand on what the code does; a law only raises the stakes.

## Accessibility standards

- WCAG 2.2 is the current W3C Recommendation (published 5 October 2023). It adds nine success criteria to WCAG 2.1 and removes 4.1.1 Parsing. Verify at: https://www.w3.org/TR/WCAG22/
- New in 2.2, Level A: 3.2.6 Consistent Help (help and contact in the same relative place across pages); 3.3.7 Redundant Entry (do not ask again for information already given in the same process, unless it is essential or for security).
- New in 2.2, Level AA: 2.4.11 Focus Not Obscured (Minimum) (the focused element is not entirely hidden by author content such as sticky headers); 2.5.7 Dragging Movements (a single-pointer alternative to every drag); 2.5.8 Target Size (Minimum) (targets at least 24 by 24 CSS px, or spaced so a 24 px circle around each does not overlap another, with exceptions for inline, equivalent, user-agent, and essential targets); 3.3.8 Accessible Authentication (Minimum) (no cognitive function test such as remembering or transcribing, unless there is an alternative, a mechanism to help such as paste and password managers, or the test is object recognition or the user's own content).
- New in 2.2, Level AAA: 2.4.12 Focus Not Obscured (Enhanced); 2.4.13 Focus Appearance; 3.3.9 Accessible Authentication (Enhanced).
- Thresholds carried from WCAG 2.1 (2018): 1.4.3 text contrast 4.5:1, or 3:1 for large text (at least 18 pt, which is 24 CSS px, or 14 pt bold, about 18.7 CSS px); 1.4.11 non-text contrast 3:1 for UI components, focus indicators, and meaningful graphics; 1.4.4 text resizable to 200 percent; 1.4.10 reflow at 320 CSS px wide with no two-dimensional scrolling; 2.5.5 Target Size (Enhanced, AAA) 44 by 44 CSS px. Verify at: https://www.w3.org/WAI/WCAG22/quickref/
- Platform touch-target guidance: Apple Human Interface Guidelines 44 by 44 pt; Material Design 48 by 48 dp. Verify at: https://developer.apple.com/design/human-interface-guidelines/accessibility and https://m3.material.io (accessibility foundations)
- WCAG 3.0 is a W3C Working Draft, not a standard; do not cite it as a requirement. Verify at: https://www.w3.org/TR/wcag-3.0/
- WAI-ARIA 1.2 is a W3C Recommendation (6 June 2023); the ARIA Authoring Practices Guide gives the keyboard patterns for custom widgets. Verify at: https://www.w3.org/TR/wai-aria-1.2/ and https://www.w3.org/WAI/ARIA/apg/

## Accessibility law (raises the stakes; does not change what the code does)

- European Accessibility Act (Directive (EU) 2019/882) applies from 28 June 2025 to many consumer products and services, including e-commerce, banking, e-books, and passenger transport services; EN 301 549 is the harmonized standard (its current version maps to WCAG 2.1 AA). Verify at: https://eur-lex.europa.eu/eli/dir/2019/882/oj
- United States, ADA Title II rule for state and local government web content and apps (published April 2024): WCAG 2.1 AA, with compliance dates of 24 April 2026 for entities serving 50,000 people or more and 26 April 2027 for smaller ones. Verify current status: https://www.ada.gov/resources/2024-03-08-web-rule/
- United States, Section 508 (federal ICT): WCAG 2.0 AA since the 2017 refresh. Verify at: https://www.access-board.gov/ict/

## Consent and deceptive design in the EU and UK

- GDPR (in force 25 May 2018): consent must be freely given, specific, informed, and unambiguous, by a clear affirmative act (Article 4(11)); withdrawing consent must be as easy as giving it (Article 7(3)); consent made a condition of a service that does not need the data is presumed not freely given (Article 7(4)); Recital 32 says silence, pre-ticked boxes, or inactivity are not consent. Verify at: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- CJEU Planet49 (C-673/17, judgment 1 October 2019): a pre-ticked checkbox is not valid consent for cookies. Verify at: https://curia.europa.eu (case C-673/17)
- EDPB Guidelines 05/2020 on consent (adopted 4 May 2020). Verify at: https://www.edpb.europa.eu
- EDPB Guidelines 03/2022 on deceptive design patterns in social media platform interfaces (version 2.0 adopted 14 February 2023): names and examples of patterns such as overloading, skipping, stirring, obstructing, fickle, and left in the dark. Verify at: https://www.edpb.europa.eu
- EDPB Cookie Banner Taskforce report (adopted 17 January 2023): most authorities treat a first layer with no reject option as an infringement, reject pre-ticked boxes, and assess deceptive button colors and contrast case by case. Verify at: https://www.edpb.europa.eu
- EU Digital Services Act (Regulation (EU) 2022/2065) Article 25: providers of online platforms must not design interfaces that deceive or manipulate users or impair free and informed decisions; it names prominence of one choice, repeated requests for a choice already made, and termination harder than subscribing as examples for guidelines. It applies to online platforms from 17 February 2024, and does not cover practices already covered by the UCPD or the GDPR. Verify at: https://eur-lex.europa.eu/eli/reg/2022/2065/oj
- EU Unfair Commercial Practices Directive (2005/29/EC), Annex I blacklist: point 7 bans falsely stating that a product or terms are available only for a very limited time to force a quick decision; the Omnibus Directive (EU) 2019/2161 added bans on fake consumer reviews (points 23b and 23c), applying from 28 May 2022. Verify at: https://eur-lex.europa.eu/eli/dir/2005/29/oj
- EU Consumer Rights Directive (2011/83/EU) Article 22: an extra payment needs the consumer's express consent; consent inferred from a default option the consumer must reject (a pre-ticked box) entitles the consumer to a refund. Verify at: https://eur-lex.europa.eu/eli/dir/2011/83/oj
- EU withdrawal function: Directive (EU) 2023/2673 adds Article 11a to the Consumer Rights Directive, requiring a withdrawal button for distance contracts concluded through an online interface, applying from 19 June 2026. Verify current status and scope: https://eur-lex.europa.eu/eli/dir/2023/2673/oj
- EU Digital Fairness Act: a Commission proposal on dark patterns, subscription traps, and addictive design was expected in 2026 after a 2025 consultation. Verify current status before citing: https://commission.europa.eu
- Germany, BGB section 312k (since 1 July 2022): online consumer contracts for continuing services need a clearly labeled cancellation button. Verify at: https://www.gesetze-im-internet.de/bgb/__312k.html
- UK Digital Markets, Competition and Consumers Act 2024: the CMA can fine for consumer-law breaches directly from 6 April 2025, and the Act bans fake reviews and addresses drip pricing; its subscription-contract rules were not yet in force at last review. Verify current status: https://www.legislation.gov.uk/ukpga/2024/13

## Subscriptions, pricing, and reviews in the US

- FTC Negative Option Rule ("click-to-cancel"), announced 16 October 2024: vacated in full by the US Court of Appeals for the Eighth Circuit on 8 July 2025 (Custom Communications, Inc. v. FTC), before its main provisions took effect. Do not cite it as law; cite ROSCA and state automatic-renewal laws instead. Verify current status (the FTC may restart the rulemaking): https://www.ftc.gov
- ROSCA, the Restore Online Shoppers' Confidence Act (2010, 15 U.S.C. 8401 to 8405): for online negative-option sales, disclose all material terms clearly before taking billing information, get express informed consent before charging, and provide a simple mechanism to stop recurring charges. The FTC enforces it (for example its case against Amazon over Prime enrollment and cancellation, filed June 2023; verify the outcome). Verify at: https://www.ftc.gov/legal-library/browse/statutes/restore-online-shoppers-confidence-act
- California Automatic Renewal Law (Business and Professions Code 17600 and following), as amended by AB 2863 with effect from 1 July 2025: express consent to the renewal terms, online cancellation for online sign-ups through a prominent direct link or button, and annual reminders. Verify current status and details: https://leginfo.legislature.ca.gov
- Other states (for example New York, Colorado, Minnesota, Virginia) have automatic-renewal laws with differing notice and cancellation rules. Verify for the product's market.
- FTC Rule on Unfair or Deceptive Fees (16 CFR Part 464), effective 12 May 2025: live-event tickets and short-term lodging must show the total price, including mandatory fees, more prominently than other prices. Verify at: https://www.ftc.gov
- FTC Rule on the Use of Consumer Reviews and Testimonials (16 CFR Part 465), effective 21 October 2024: bans fake reviews and testimonials, buying positive reviews, review suppression, and fake social-media indicators. Verify at: https://www.ftc.gov
- CAN-SPAM Act: every commercial email needs a working opt-out, honored within 10 business days. Verify at: https://www.ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business
- RFC 8058 (January 2017) defines one-click unsubscribe (List-Unsubscribe-Post). Gmail and Yahoo require it from bulk senders (about 5,000 or more messages a day), enforced from 2024. Verify at: https://www.rfc-editor.org/rfc/rfc8058 and the providers' sender guidelines

## Performance

- Core Web Vitals "good" thresholds at the 75th percentile of page loads: Largest Contentful Paint 2.5 s or less, Interaction to Next Paint 200 ms or less, Cumulative Layout Shift 0.1 or less ("poor": LCP over 4 s, INP over 500 ms, CLS over 0.25). INP replaced First Input Delay as a Core Web Vital on 12 March 2024. Verify at: https://web.dev/articles/vitals
- RAIL model: respond to input within 100 ms (handle it within 50 ms), produce animation frames within about 16 ms, and treat main-thread tasks over 50 ms as long tasks. Verify at: https://web.dev/articles/rail
- Doherty threshold: productivity rises when a system responds within 400 ms (Doherty and Thadani, IBM, 1982). Verify at: https://lawsofux.com/doherty-threshold/

## Usability, content, and process references

- Nielsen's 10 usability heuristics (1994; wording refreshed 2020); severity ratings run 0 to 4, and this skill maps 4 to Critical, 3 to High, 2 to Medium, 1 to Low. Verify at: https://www.nngroup.com/articles/ten-usability-heuristics/
- ISO 9241-11:2018 defines usability as effectiveness, efficiency, and satisfaction for specified users, goals, and context of use. ISO 9241-110:2020 lists seven interaction principles: suitability for the user's tasks, self-descriptiveness, conformity with user expectations, learnability, controllability, use error robustness, and user engagement. Verify at: https://www.iso.org
- ISO 24495-1:2023, Plain language, Part 1: governing principles and guidelines. The US Plain Writing Act of 2010 applies to federal agencies. Verify at: https://www.iso.org (search 24495-1) and https://www.plainlanguage.gov
- deceptive.design (Harry Brignull, formerly darkpatterns.org) keeps the pattern taxonomy the TRU cards use: comparison prevention, confirmshaming, disguised ads, fake scarcity, fake social proof, fake urgency, forced action, hard to cancel, hidden costs, hidden subscription, nagging, obstruction, preselection, sneaking, trick wording, visual interference. Verify at: https://www.deceptive.design/types
- Stanford Guidelines for Web Credibility (B.J. Fogg, 2002). Verify at: https://credibility.stanford.edu/guidelines/
- BPMN 2.0 (OMG, 2011), also ISO/IEC 19510:2013. Verify at: https://www.omg.org/spec/BPMN/2.0
- Baymard Institute publishes the form and checkout usability research the FRM cards draw on (single full-name field, inline validation on blur, never clear the form on error). Verify at: https://baymard.com/research
- HTML autofill tokens (`email`, `tel`, `given-name`, `street-address`, `postal-code`, `cc-number`, `one-time-code`, `current-password`, `new-password`) are defined in the WHATWG HTML Living Standard. Verify at: https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#autofill
