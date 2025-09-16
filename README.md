# MTurk Cyberbullying Survey Generator

A Node.js script that generates HTML surveys for Amazon Mechanical Turk to collect cyberbullying annotations on Instagram comments.

## What it does

Takes Instagram session data and generates interactive HTML surveys where MTurk workers annotate:

**Cyberbullying Detection**: Yes/No

**Severity Levels**:
- Mild
- Moderate  
- Severe

**Cyberbullying Topics**:
- Sexual but not Gender Identity
- Physical Appearance
- Gender Identity and Sexual Orientation
- Disability and Neurodiversity
- Social Status/Popularity
- Race and Ethnicity
- Intellectual and Academic
- Religious
- Political
- Other

**Comment Author Roles**:
- Passive Bystander
- Bully
- Bully Assistant
- Aggressive Victim
- Aggressive Defender of Victim
- Non-Aggressive Victim
- Non-Aggressive Defender of Victim (with sub-options: Direct, Support)

**Main Victim Options**:
- The user who created the post
- Participants in the comments
- People depicted in the picture
- Other
  
## Usage

```bash
node Mturk.js
```

# ML Models

The ML Models directory contains code for cyberbullying detection using:

- Logistic Regression (LR)
- Naïve Bayes (NB)
- Random Forest (RF)
- Support Vector Machine (SVM)
- BERT
- RoBERTa
- CyberBERT