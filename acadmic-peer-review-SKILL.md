---
name: conference-submission-review
description: >
  Conduct structured peer reviews of academic conference or journal submissions in health
  informatics, biomedical informatics, and related fields. Use this skill whenever a user asks
  to review, evaluate, screen, or provide feedback on a conference or journal submission, or
  wants to self-check and improve their own paper before submitting. Also triggers when a user
  provides a PDF or document and mentions conference review, peer review, scientific program
  committee, SPC, submission feedback, or paper improvement. Originally developed for the AMIA
  Annual Symposium review process; the criteria and workflow are broadly applicable to other
  venues. At the start of each session, the agent will ask the user for the review context
  (conference details and review purpose) before proceeding.
---

# Conference Submission Review Skill

A structured workflow for peer reviewing academic submissions in health informatics and related
fields. Originally developed based on the AMIA Annual Symposium Scientific Program Committee
(SPC) review process, but designed to be applied to any conference or journal venue.

This skill will be refined over time as it is applied across more submissions and venues.

---

## Session Initialisation: Ask These Questions First

Before beginning any review, ask the user the following. Collect all answers before proceeding.

### 1. Review Purpose

> "Is this review part of a formal peer review process (e.g., deciding whether to accept a
> submission), or are you looking for help improving your own submission before you submit it?"

- **Peer review**: Follow the standard review workflow. Provide balanced, objective feedback
  suitable for the programme committee. Keep detailed suggestions concise.
- **Self-improvement**: Follow the same review criteria and structure, but provide more detailed
  feedback and concrete suggestions for improvement. You may offer rewritten sentences,
  restructured arguments, or example learning objectives. The goal is to maximise the quality
  of the submission.

### 2. Conference / Venue Details

> "Which conference or journal is this submission for? If you have a link to the call for
> submissions or author guidelines, please share it."

- If a URL is provided: fetch and crawl the page to extract:
  - Conference theme and thematic areas
  - Submission types accepted and their page/word limits
  - File format requirements (PDF, Word, etc.)
  - Page size and margin requirements
  - Abstract word count requirements
  - Reference format required
  - Any specific required sections or elements
  - Learning objective or CME/CPD requirements
  - Any stated criteria for acceptance/rejection

- If no URL is provided: ask for the conference name and year, then search the web for
  the call for submissions. If nothing can be found, proceed using the AMIA defaults
  (documented in the Reference Defaults section below) and note to the user that defaults
  are being used.

- If the submission is a **draft document (Word/DOCX or other non-PDF format)**: note this
  to the user. A draft format is fine for self-improvement reviews, but for formal peer
  review the final submission is typically required in PDF. Flag any format conversion
  considerations if relevant.

---

## Step 1: Identify Submission Type and Check Format Compliance

Screen the submission against the requirements identified for the target venue. Flag any
non-compliance prominently, as many venues explicitly state that non-compliant submissions
may be rejected without review.

### How to Check Page Count from PDF
```python
import re
with open('submission.pdf', 'rb') as f:
    content = f.read().decode('latin-1')
mediaboxes = re.findall(r'MediaBox[^]]*\[ *0 *0 *([\d.]+) *([\d.]+)', content)
print('Pages:', len(mediaboxes), '| Sizes:', set(mediaboxes))
```
Note: Submission system cover pages may add 1 extra page — check whether the first page is
a system-generated cover sheet and exclude it from the count.

### Universal Format Checks (apply to all venues unless guidelines state otherwise)
- Correct file format (PDF for final submission; Word/DOCX acceptable for drafts)
- Page size matches venue requirement (AMIA default: U.S. Letter, 612 x 792 pt)
- Margins within requirement
- Single or multi-column layout as specified
- Author names, degrees, and institutional affiliations present
- Abstract present and within word count range for the submission type
- At least one learning objective (where required by the venue)
- References in the required style (default: Vancouver — see Reference Defaults)
- Page count within the limit for the submission type (including all tables, figures,
  references, and acknowledgements)

### Submission Portal Exceptions
Some venues (including AMIA) allow certain elements to be entered in the submission portal
rather than the document itself. Common examples:
- Abstract (for posters, short abstracts, system demonstrations)
- Author information
If the user confirms these were submitted via portal, do not flag their absence in the document.

---

## Step 2: Assess Learning Objectives

Many health informatics conferences (particularly those with CME/CPD accreditation) require
measurable learning objectives. Check whether this is required for the target venue.

Where learning objectives are required, they must complete the sentence:
> "After participating in my session the learner will be able to..."

### Good vs Poor Objectives
- **Good action verbs**: describe, identify, compare, apply, construct, evaluate, distinguish,
  explain, demonstrate, design, analyse, implement, interpret
- **Poor/non-measurable verbs**: understand, know, learn, appreciate, recognise, be aware of
- **Not acceptable**: topic headings (e.g., "How to use HMMs") — must be rewritten as outcomes
- **Not acceptable**: narrative paragraph format — must be discrete numbered or bulleted statements

Always provide a concrete rewritten example when flagging a poorly formed objective.

---

## Step 3: Assess Research Ethics

For submissions involving human subjects research, check for:
- IRB approval statement (or equivalent ethics committee approval)
- Informed consent disclosure, especially for:
  - Video or audio recording of patients or clinicians
  - Wearable or sensor data
  - Sensitive clinical or behavioural data
- Data use agreement for third-party datasets (e.g., consumer health apps, MIMIC, claims data)

Flag the absence of any of these as a "No" in the supplementary questions with a one-sentence
explanation. For panels, debates, and purely technical system demonstrations with no human
subjects research, mark as N/A.

---

## Step 4: Rate the Submission

Provide numerical ratings on a 0-5 scale (0 = not rated). Adapt labels to the venue where
needed, but these criteria apply broadly:

| Criterion                  | What to assess |
|----------------------------|----------------|
| Importance / significance  | Clinical or scientific relevance; novelty of the problem |
| Scholarship / literature   | Adequacy of literature review; citation quality |
| Methods                    | Appropriateness and rigour of study or system design |
| Results / analyses         | Quality of evidence; appropriateness of analytical approach |
| Clarity / writing          | Organisation, readability, logical flow |
| Overall recommendation     | Holistic suitability for the venue |
| Reviewer confidence        | How confident you are in assessing this topic area |

---

## Step 5: Write Comments for the Authors

### For peer review
- 200-250 words
- Must NOT include accept/reject recommendation
- Constructive and actionable
- Do NOT describe what the paper is about

### For self-improvement review
- No strict word limit — be as detailed as is useful
- May include specific rewritten sentences, restructured sections, or example objectives
- May include an honest accept/reject opinion if the user requests one
- Focus on maximising submission quality

### Structure (both modes)
- Open with a brief positive statement on the strongest element
- Use bullet points for specific, actionable feedback
- Keep bullets concise — 1-3 sentences each
- Do not use em dash characters (use commas or colons instead)

### Topics to address as relevant
1. Suitability for the conference audience
2. Contribution to the field
3. Adequacy of literature review and contextualisation
4. Suitability and rigour of methods
5. Appropriateness of analyses and importance of results
6. Specific ways the submission could be improved

### Common feedback patterns by submission type

**Papers:**
- Are claims supported by adequate evidence?
- Is the study design appropriate for the research question?
- Are limitations acknowledged?
- Is statistical methodology sound?
- Are ML accuracy metrics interpreted in the context of class balance?

**Posters:**
- Is the contribution sufficiently novel for the audience?
- Are results clearly visualised?
- Is the sample size adequate for the conclusions drawn?

**System Demonstrations:**
- Is validation complete, or still prospective?
- Are claims of superiority over baselines supported by named comparators and data?
- Does the live demo align with the written description?

**Panels:**
- Is the speaker lineup complementary and appropriately credentialed?
- Is the session structure clear and feasible within the time allocation?
- Is there sufficient audience interaction planned?
- Is there a statement confirming all panelists have agreed to participate?

---

## Step 6: Write Confidential Comments for the Programme Committee

(Skip this section for self-improvement reviews unless the user requests it.)

- Brief: typically 3-6 sentences
- May include accept/reject recommendation explicitly
- Authors will NOT see these comments
- Avoid repeating what is already in the author comments

Structure:
- State recommendation clearly (accept / reject / accept with revisions)
- Summarise key strength(s) in 1-2 sentences
- Note any concerns that should influence the committee decision
- Flag anything not covered in author comments (ethical concerns, conflicts of interest,
  overlap with other known submissions)

---

## Step 7: Answer Supplementary Questions

Not all supplementary questions will apply to every venue or submission type. Use N/A where
a question genuinely does not apply. For any "No" answer, provide a single brief explanatory
sentence. Answer in this order:

1. **Inclusive language**: Does the submission use respectful, inclusive language free from
   stigmatising, stereotyping, or exclusionary terms? This applies to all venues regardless
   of whether a specific style guide is referenced.

2. **Research ethics**: Are research ethics (study design, consent including data consent,
   ethical approval) addressed appropriately?

3. **Subject matter match**: Does this submission match the conference/venue subject matter
   based on your expertise? Note the relevant track or theme if applicable.

4. **AI tool use**: Did you use an AI tool in conducting this review?
   Standard disclosure: "Claude (Anthropic) was used as a review assistant: to screen
   submissions for format compliance, as a sounding board for evaluating scientific merit,
   and to help draft and edit review comments."

5. **Patient care recommendations**: Are any recommendations for patient care based on current
   science, evidence, and clinical reasoning, with a fair and balanced view of options?

6. **Scientific standards**: Does all scientific research referred to, reported, or used conform
   to accepted standards of experimental design, data collection, analysis, and interpretation?

7. **Emerging topics**: Are new and evolving topics for which there is a lower or absent
   evidence base clearly identified as such?

8. **Evidence-based practice**: Does the activity avoid advocating for practices not adequately
   based on current science, evidence, and clinical reasoning?

9. **No unscientific approaches**: Does the activity exclude advocacy for unscientific approaches
   to diagnosis or therapy, or practices where risks outweigh benefits?

10. **Learning objectives**: Are the learning objectives appropriate and measurable for the
    content as written?

---

## Key Principles for High-Quality Reviews

### Scientific rigour
- Distinguish between feasibility/pilot studies and definitive studies; hold each to
  appropriate standards
- For ML papers: check for class imbalance, dataset size limitations, and whether accuracy
  metrics are appropriate given class distribution — a model favouring the majority class
  can appear accurate without detecting anything useful
- For system papers: check whether validation is prospective or retrospective, and whether
  superiority claims are supported by quantitative evidence with named comparators
- For observational studies: check for confounders and whether causal language is used
  appropriately

### Format
- Abstract and author info entered via portal are not absent from the submission — confirm
  with the user before flagging
- Submission system cover pages do not count toward the page limit
- A draft in Word/DOCX format is acceptable for self-improvement reviews; note if the venue
  requires PDF for final submission

### Tone
- Be constructive — the goal is to help authors improve their work
- Be specific — "the model selection rationale does not explain why N=6 states was preferred
  over the statistically favoured N=8" is more useful than "needs more detail"
- Be honest — if work is not ready, say so clearly in committee comments while remaining
  respectful in author comments
- Do not describe what the paper is about in author comments — the authors know

---

## Reference Defaults (AMIA Annual Symposium)

Use these defaults when no venue-specific guidelines are available.

### Page Limits

| Submission Type         | Abstract (words) | Page Limit |
|-------------------------|------------------|------------|
| Paper - Regular         | 125-150          | 10         |
| Paper - Student         | 125-150          | 10         |
| Poster                  | 50-75*           | 1          |
| Podium Abstract         | 50-75*           | 2          |
| Panel                   | 125-150          | 3          |
| System Demonstration    | 50-75*           | 1          |
| Informatics Debate      | 150              | 3          |
| Workshop                | 250-300          | 4          |

*Abstract entered in submission portal; does not need to appear in the document.

### Format Defaults
- File format: PDF
- Page size: U.S. Letter (8.5 x 11 inch / 612 x 792 pt)
- Margins: 1 inch all sides
- Layout: Single column
- Reference style: Vancouver (www.icmje.org) — only first word of article title capitalised
- Learning objectives: Required for all submission types

### Thematic Areas (AMIA 2026)
- Clinical informatics
- Translational bioinformatics
- Public health informatics
- Informatics education
- NLP and AI methods
- Health information management

---

## Quick Reference: Common Issues to Check

| Issue | Types Most Affected |
|-------|---------------------|
| Learning objectives use non-measurable verbs ("understand", "recognise") | All |
| Learning objectives written as narrative paragraph | All |
| Missing ethics/IRB statement for human subjects research | Papers, posters |
| Prospective validation described as if already complete | System demos, papers |
| ML accuracy not contextualised by class balance | Papers, posters |
| Comparator models unnamed in benchmarking | Papers, system demos |
| Missing panelist agreement statement | Panels |
| Abstract exceeds word limit for submission type | Posters, system demos |
| Duplicated passages in methods section | Papers |
| Discussion overstates clinical applicability of observational findings | All |
| No references or very sparse citations | System demos, posters |
| Draft submitted in Word format rather than PDF | All (for formal peer review) |
