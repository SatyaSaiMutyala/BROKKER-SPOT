# SmartHR — React.js Frontend Development
## Time & Cost Estimation Document

| | |
|---|---|
| **Project** | HRM / CRM Web Application — Frontend (SmartHR reference design) |
| **Reference UI** | https://smarthr.dreamstechnologies.com/html/index.html |
| **Scope** | **All modules — complete.** Frontend only (React.js). No backend, database, or APIs. |
| **Total Cost** | **₹2,50,000** |
| **Total Duration** | **3 months (13 weeks)** |
| **Delivery Model** | 2 phases — Phase 1: ₹1,80,000 / 10 weeks · Phase 2: ₹70,000 / 3 weeks |
| **Document Date** | 26 July 2026 |
| **Version** | 2.1 |
| **Currency** | INR (₹) |

---

## 1. Executive Summary

Complete frontend rebuild of the SmartHR HRM/CRM application in React.js — **all 273 screens across 15 module groups**, including the full UI Interface component library and all 14 layout variants.

| | Phase 1 | Phase 2 | **Total** |
|---|---:|---:|---:|
| **Screens** | 225 | 48 | **273** |
| **Effort (hours)** | 1,160 | 311 | **1,471** |
| **Duration** | 10 weeks (Wk 1–10) | 3 weeks (Wk 11–13) | **13 weeks** |
| **Cost** | **₹1,80,000** | **₹70,000** | **₹2,50,000** |
| **Team** | 3 developers | 2 developers | — |

### Phase 1 — ₹1,80,000 / 10 weeks (225 screens)

Foundation & design system · **UI Interface component library (67 pages)** · **14 layout variants** · **Authentication (21)** · **Dashboards — all 12 role dashboards (12)** · **Super Admin (11)** · **CRM (7)** · **HRM (37)** · **Recruitment (5)** · **Finance & Accounts (13)** · **Administration (17)** · **Settings (35)**

### Phase 2 — ₹70,000 / 3 weeks (48 screens)

AI Center (5) · Applications suite — Chat, Calls, Email, Calendar, Kanban, File Manager (14) · Projects (6) · Pages (13) · Content Management (10)

> **All 12 role dashboards are delivered in Phase 1** — Admin, Employee, Deals, Leads, HR, Payroll, Recruitment, Attendance, Finance, IT Admin, Asset and Help Desk — within the **Phase 1 cost of ₹1,80,000**. No dashboard is deferred to Phase 2.

### Commercial basis

| Item | Value |
|---|---|
| Total effort | 1,471 hours |
| Total screens | 273 |
| **Total contracted cost** | **₹2,50,000** |

> ### ⚠️ Critical prerequisite — please read
>
> This price and timeline are achievable **only** because the build starts from the **official SmartHR React template**.

---

## 2. Assumptions

| # | Assumption |
|---|---|
| A1 | **Frontend only.** No backend, database, server logic, authentication service, or business-rule implementation. |
| A2 | All screens are built **API-ready** — data access is abstracted into a service layer wired to mock data (MSW / JSON fixtures). Live API integration is not included (§9). |
| A3 | **No new UI/UX design work.** The SmartHR template is the design specification. Any newly designed or custom screen is a change request. |
| A4 | Static assets (icons, illustrations, images, fonts) are sourced from the template. |
| A5 | Browser support: latest 2 versions of Chrome, Edge, Firefox, Safari. No IE11. |
| A6 | Responsive at 4 breakpoints — Desktop 1440, Laptop 1280, Tablet 768, Mobile 375. Responsive, not a separate mobile redesign. |
| A7 | **"Dashboard module" in Phase 1 = all 12 role dashboards, built complete** — Admin, Employee, Deals, Leads, HR, Payroll, Recruitment, Attendance, Finance, IT Admin, Asset and Help Desk. No dashboard remains in Phase 2. |
| A8 | Language: English. i18n scaffolding and RTL layout are included in Phase 1 (part of layout variants); translation content is not. |
| A9 | Client feedback within **2 business days** per sprint review. Delays shift the timeline day-for-day. |
| A10 | Cost excludes hosting, third-party licenses, and paid libraries. |

---

## 3. Technology Stack

| Layer | Choice |
|---|---|
| Framework | **React 18** + TypeScript |
| Build tool | **Vite** |
| Base | **Official SmartHR React template** |
| Routing | React Router v6 — lazy loading + route-level code splitting |
| Styling | **Bootstrap 5 + SCSS** (template's existing architecture) |
| State | Zustand (UI state) + **TanStack Query** (server state, caching, pagination) |
| Forms | React Hook Form + Zod validation |
| Tables | TanStack Table — sort, filter, paginate, column visibility, CSV export |
| Charts | **ApexCharts** (react-apexcharts) — matches template |
| Calendar | FullCalendar — calendar, shift & schedule, holiday calendar |
| Drag & Drop | dnd-kit — Kanban, Task Board, CRM Pipeline |
| Rich text | TipTap — email composer, notes, blog editor |
| Date | Day.js + react-datepicker |
| Icons | Tabler / Feather / Remix / Bootstrap / FontAwesome (as per template) |
| Mock API | **MSW** — every screen runs standalone before the backend exists |
| Quality | ESLint, Prettier, Husky, lint-staged |
| Testing | Vitest + React Testing Library (component/smoke level) |
| Docs | Storybook — shared component layer |

---

## 4. PHASE 1 — ₹1,80,000 / 10 Weeks / 225 Screens

### 4.1 Foundation & Design System

| Item | Hours |
|---|---:|
| Template integration, Vite + TypeScript migration, project architecture, ESLint/Prettier/Husky | 22 |
| Design tokens, SCSS theme override, client branding, light + dark mode verification | 20 |
| Application shell — multi-level collapsible sidebar, sidebar search (Ctrl+/), header, notifications dropdown, breadcrumbs, footer | 24 |
| Role-based menu rendering + route guards + lazy loading | 14 |
| Shared component standardization layer — DataTable wrapper, form control set, modal/offcanvas, pickers, file upload, toast, wizard, skeletons | 30 |
| API service layer — Axios interceptors, TanStack Query setup, MSW mock server, fixture data | 20 |
| **Subtotal** | **130** |

### 4.2 UI Interface & Layout *(explicitly in Phase 1 per client scope)*

| Group | Screens | Scr. | Hours |
|---|---|---:|---:|
| **Base UI** | Alerts, Accordion, Avatar, Badges, Breadcrumb, Buttons, Button Group, Card, Carousel, Collapse, Dropdowns, Ratio, Grid, Images, Links, List Groups, Modals, Offcanvas, Pagination, Placeholders, Popovers, Progress, Spinner, Tabs, Toasts, Tooltips, Typography | 27 | 12 |
| **Advanced UI** | Dragula, Clipboard, Sweet Alerts, Lightbox, Scrollbar | 5 | 4 |
| **Forms** | Basic Inputs, Checkbox & Radios, Input Groups, Grid & Gutters, Form Select, Input Masks, File Uploads, Horizontal/Vertical/Floating layouts, Validation, Select2, Wizard, Picker | 14 | 8 |
| **Tables** | Basic Tables, Data Table | 2 | 2 |
| **Charts** | Apex, C3, Chart.js, Morris, Flot, Peity | 6 | 6 |
| **Icons** | 13 icon set pages | 13 | 4 |
| **Layout variants** | Horizontal, Detached, Modern, Two Column, Hovered, Boxed, Horizontal Single, Horizontal Overlay, Horizontal Box, Menu Aside, Transparent, Without Header, RTL, Dark | — | 24 |
| **Subtotal** | | **67** | **60** |

### 4.3 Authentication

| Screens | Scr. | Hours |
|---|---:|---:|
| Login, Register, Forgot Password, Reset Password, Email Verification, 2-Step Verification — each in 3 variants (Cover / Illustration / Basic) = 18, plus Lock Screen, 404 Error, 500 Error | 21 | 32 |

### 4.4 Dashboards *(all 12 role dashboards — complete)*

Every dashboard in the reference application's Dashboard menu is delivered in Phase 1. Each is a composite screen: KPI stat tiles, multiple ApexCharts visualisations, list/table widgets, filters and date-range controls, built responsive across all 4 breakpoints.

| # | Screen | Principal content | Hours |
|---:|---|---|---:|
| 1 | **Admin Dashboard** | Stat tiles, employee/department charts, attendance overview, todo, invoices, activity feed | 13 |
| 2 | **Employee Dashboard** | Leave balance, attendance punch in/out, tasks, team, upcoming holidays, performance | 12 |
| 3 | **HR Dashboard** | Headcount, hiring pipeline, attrition, department split, birthdays, announcements | 11 |
| 4 | **Deals Dashboard** | Deal value pipeline, stage-wise conversion, won/lost analysis, top deals, rep leaderboard | 8 |
| 5 | **Leads Dashboard** | Lead volume trend, source breakdown, conversion funnel, lead status split, recent leads | 8 |
| 6 | **Payroll Dashboard** | Payroll cost trend, department-wise salary split, deductions/benefits, payslip status, upcoming payruns | 8 |
| 7 | **Recruitment Dashboard** | Open positions, applications trend, candidate pipeline stages, source effectiveness, interview schedule | 8 |
| 8 | **Attendance Dashboard** | Present/absent/late split, attendance trend, department-wise attendance, leave overview, punch records | 8 |
| 9 | **Finance Dashboard** | Income vs expense, revenue trend, invoice/payment status, budget utilisation, transaction list | 9 |
| 10 | **IT Admin Dashboard** | Ticket volume, system/asset health, request status, resolution time, IT activity log | 8 |
| 11 | **Asset Dashboard** | Asset inventory split, allocation status, category-wise distribution, warranty expiry, recent assignments | 7 |
| 12 | **Help Desk Dashboard** | Ticket status split, SLA compliance, priority breakdown, agent performance, ticket queue | 8 |
| | **Subtotal (12 screens)** | | **108** |

### 4.5 Super Admin *(complete)*

| Screens | Scr. | Hours |
|---|---:|---:|
| Super Admin Dashboard, Companies, Subscriptions, Packages, Domain, Purchase Transaction, Tenant Usage Metrics, Tenant Support Tickets, Ticket Agents, SLA Policies, Escalation Rules | 11 | 48 |

### 4.6 CRM *(complete)*

| Screens | Scr. | Hours |
|---|---:|---:|
| Contacts (6), Companies (6), Deals (6), Leads (6), Pipeline — drag & drop (8), Analytics — charts (5), Activities (3) | 7 | 40 |

### 4.7 HRM *(complete, excluding Recruitment — itemised separately)*

| Sub-group | Screens | Scr. | Hours |
|---|---|---:|---:|
| **Employees** | Employee Lists, Employee Grid, Employee Details, Departments, Designations, Policies | 6 | 30 |
| **Tickets** | Tickets, Ticket Details, Ticket Automation, Ticket Reports | 4 | 22 |
| **General** | Holidays | 1 | 4 |
| **Attendance & Leaves** | Leaves (Admin), Leave (Employee), Leave Settings, Attendance (Admin), Attendance (Employee), Timesheets, Shift & Schedule, Shift Swap Requests, Overtime, Holiday Calendar, WFH Management | 11 | 52 |
| **Performance** | Performance Indicator, Performance Review, Performance Appraisal, Goal List, Goal Type | 5 | 24 |
| **Training** | Training List, Trainers, Training Type, Certification Tracking, Learning Analytics | 5 | 22 |
| **Career Management** | Probation Management, Notice Period Tracker, Promotion, Resignation, Termination | 5 | 21 |
| **Subtotal** | | **37** | **175** |

### 4.8 Recruitment *(complete)*

| Screens | Scr. | Hours |
|---|---:|---:|
| Jobs, Candidates, Referrals, Resume Parsing, Campus Hiring | 5 | 28 |

### 4.9 Finance & Accounts *(complete)*

| Sub-group | Screens | Scr. | Hours |
|---|---|---:|---:|
| **Sales** | Estimates, Invoices (builder + print view), Payments, Expenses, Provident Fund, Taxes | 6 | 28 |
| **Accounting** | Categories, Budgets, Budget Expenses, Budget Revenues | 4 | 14 |
| **Payroll** | Employee Salary, Payslip (print/PDF layout), Payroll Items | 3 | 14 |
| **Subtotal** | | **13** | **56** |

### 4.10 Administration *(complete)*

| Sub-group | Screens | Scr. | Hours |
|---|---|---:|---:|
| **Assets** | Assets, Asset Categories | 2 | 8 |
| **Help & Support** | Knowledge Base, Activities | 2 | 8 |
| **User Management** | Users, Roles & Permissions (permission matrix) | 2 | 14 |
| **Reports** | Expense, Invoice, Payment, Project, Task, User, Employee, Payslip, Attendance, Leave, Daily | 11 | 36 |
| **Subtotal** | | **17** | **66** |

### 4.11 Settings *(complete — 35 screens under Administration)*

| Group | Screens | Scr. | Hours |
|---|---|---:|---:|
| **General** | Profile, Security, Notifications, Connected Apps | 4 | 10 |
| **Website** | Business Settings, SEO, Localization, Prefixes, Preferences, Appearance, Language, Authentication, AI Settings | 9 | 23 |
| **App** | Salary Settings, Approval Settings, Invoice Settings, Leave Type, Custom Fields | 5 | 14 |
| **System** | Email Settings, Email Templates, SMS Settings, SMS Templates, OTP, GDPR Cookies, Maintenance Mode | 7 | 18 |
| **Financial** | Payment Gateways, Tax Rate, Currencies | 3 | 8 |
| **Other** | Custom CSS, Custom JS, Cronjob, Storage, Ban IP Address, Backup, Clear Cache | 7 | 15 |
| **Subtotal** | | **35** | **88** |

### 4.12 Phase 1 Roll-Up

| Category | Scr. | Hours |
|---|---:|---:|
| Foundation & Design System | — | 130 |
| UI Interface & Layout variants | 67 | 60 |
| Authentication | 21 | 32 |
| **Dashboards (all 12 role dashboards)** | **12** | **108** |
| Super Admin | 11 | 48 |
| CRM | 7 | 40 |
| HRM | 37 | 175 |
| Recruitment | 5 | 28 |
| Finance & Accounts | 13 | 56 |
| Administration | 17 | 66 |
| Settings | 35 | 88 |
| **Build subtotal** | **225** | **831** |
| QA & bug fixing | | 133 |
| Cross-browser + responsive verification (4 breakpoints) | | 64 |
| Client revision / rework allowance | | 132 |
| **PHASE 1 TOTAL** | **225** | **1,160** |

| Phase 1 Commercials | |
|---|---|
| Effort | 1,160 hours |
| **Cost** | **₹1,80,000** |
| **Duration** | **10 weeks — Weeks 1–10** |
| **Team** | 1 Senior React Developer + 2 React Developers (all full-time) |

---

## 5. PHASE 2 — ₹70,000 / 3 Weeks / 48 Screens

### 5.1 Scope

*No dashboards remain in Phase 2 — all 12 are delivered in Phase 1 (§4.4).*

| Module | Screens | Scr. | Hours |
|---|---|---:|---:|
| **AI Center** | AI Attendance Insights, AI Payroll Forecast, AI Hiring Forecast, AI Team Performance Insights, AI Settings | 5 | 28 |
| **Applications** | Chat (18), Voice Call, Video Call, Outgoing Call, Incoming Call, Call History (20), Calendar (9), Email (14), To Do (6), Notes (5), Social Feed (7), File Manager (9), Kanban (11), Invoices (5) | 14 | 104 |
| **Projects** | Clients, Client Details, Projects, Project Details, Tasks, Task Board | 6 | 30 |
| **Pages** | Starter, Profile, Profile Settings, Gallery, Search Results, Timeline, Pricing, Coming Soon, Under Maintenance, Under Construction, API Keys, Privacy Policy, Terms & Conditions | 13 | 32 |
| **Content Management** | Pages, All Blogs, Blog Categories, Comments, Blog Tags, Countries, States, Cities, Testimonials, FAQs | 10 | 26 |
| **Build subtotal** | | **48** | **220** |
| QA & bug fixing | | | 36 |
| Cross-browser + responsive verification | | | 14 |
| Client revision / rework allowance | | | 41 |
| **PHASE 2 TOTAL** | | **48** | **311** |

| Phase 2 Commercials | |
|---|---|
| Effort | 311 hours |
| **Cost** | **₹70,000** |
| **Duration** | **3 weeks — Weeks 11–13** |
| **Team** | 2 React Developers (full-time) + shared QA |

---

## 6. Programme Roll-Up — All Modules

| Phase | Modules | Scr. | Hours | Cost | Timeline |
|---|---|---:|---:|---:|---|
| **Phase 1** | Foundation, UI Interface & Layouts, Authentication, **Dashboards — all 12**, Super Admin, CRM, HRM, Recruitment, Finance & Accounts, Administration, Settings | 225 | 1,160 | **₹1,80,000** | Weeks 1–10 |
| **Phase 2** | AI Center, Applications, Projects, Pages, Content Management | 48 | 311 | **₹70,000** | Weeks 11–13 |
| **TOTAL** | **All modules — complete** | **273** | **1,471** | **₹2,50,000** | **13 weeks (3 months)** |

---

## 7. Team & Capacity

### Phase 1 — 3 developers, 10 weeks

| Role | Allocation | Responsibility |
|---|---|---|
| **Senior React Developer** | Full-time | Template integration, architecture, design system, shared component layer, **all 12 role dashboards (chart-heavy composites)**, complex screens (Employee Details, Roles & Permissions matrix, Shift & Schedule, CRM Pipeline, Invoice builder), code review |
| **React Developer** ×2 | Full-time | Module screens, data tables, forms, Settings pages, Reports, Authentication, UI Interface pages, dashboard widget assembly, responsive implementation |
| QA / Tester | Shared ~15% | Cross-browser, responsive, functional verification *(drawn from the QA allocation)* |

**Capacity check:** 3 FTE × 50 working days × 8 h = **1,200 hours** available vs **1,160 hours** required. Utilisation 97% — minimal float. Scope must remain frozen.

### Phase 2 — 2 developers, 3 weeks

2 FTE × 15 working days × 8 h = 240 h + shared QA 71 h = **311 hours** — matches requirement exactly.

---

## 8. Delivery Schedule — 13 Weeks

### Phase 1 (Weeks 1–10)

| Sprint | Weeks | Deliverables | Hours |
|---|---|---|---:|
| **S1** | 1–2 | Template integration, Vite/TS setup, theme + branding, light/dark, application shell (sidebar, header, breadcrumbs), routing + role guards, API layer + MSW mocks, **14 layout variants**, **UI Interface — 67 pages**, **Authentication — 21 screens** | 240 |
| **S2** | 3–4 | **HRM** — Employees (6), Departments, Designations, Policies, Holidays, Attendance & Leaves (11), Tickets (4), Performance (5), Training (5), Career Management (5), **Recruitment (5)** | 240 |
| **S3** | 5–6 | **Dashboards — all 12** (Admin, Employee, Deals, Leads, HR, Payroll, Recruitment, Attendance, Finance, IT Admin, Asset, Help Desk), **CRM (7)**, **Super Admin (11)** | 240 |
| **S4** | 7–8 | **Finance & Accounts (13)**, **Administration (17)** — Assets, Help & Support, User Management, Roles & Permissions, Reports (11); **Settings (35)** | 240 |
| **Hardening** | 9–10 | Responsive pass across 4 breakpoints, cross-browser, dashboard chart tuning, bug fixing, Storybook docs, Phase 1 handover | 200 |

### Phase 2 (Weeks 11–13)

| Sprint | Weeks | Deliverables | Hours |
|---|---|---|---:|
| **S5** | 11–12 | Applications suite (14) — Chat, Calls, Calendar, Email, To Do, Notes, Social Feed, File Manager, Kanban, Invoices; **Projects (6)**, **AI Center (5)** | 200 |
| **S6** | 13 | **Pages (13)**, **Content Management (10)**; final QA, responsive pass, documentation, handover | 111 |

### Milestones

| M | Week | Milestone | Phase |
|---|---|---|---|
| M1 | 2 | Shell + theming + UI Interface library + Authentication complete and navigable | 1 |
| M2 | 4 | HRM + Recruitment complete (42 screens) — first full end-to-end demo | 1 |
| M3 | 6 | **All 12 Dashboards** + CRM + Super Admin complete — full dashboard demo | 1 |
| M4 | 8 | Finance & Accounts + Administration + Settings complete — all 225 Phase 1 screens code-complete | 1 |
| M5 | 10 | **Phase 1 delivery** — tested, responsive, documented | 1 |
| M6 | 12 | Applications + Projects + AI Center complete | 2 |
| M7 | 13 | **Final delivery — all 273 screens, complete sign-off** | 2 |

---

## 9. Exclusions, Warranty & Change Control

### Not included

- Backend / API development, database design, server infrastructure
- Live API integration — replacing the MSW mocks with live REST endpoints
- UI/UX design, wireframing, branding, or logo design
- Content writing, data entry, data migration
- DevOps, CI/CD, hosting, domain, SSL
- Native mobile applications (iOS / Android)
- Third-party licenses, premium fonts, paid libraries
- Translation content for i18n *(framework and RTL layout are included; translated strings are not)*
- Automated E2E test suites (Cypress / Playwright), load / performance testing
- WCAG 2.1 AA certification *(basic accessibility hygiene included; formal audit is not)*
- Support beyond the warranty period below

### Warranty

**30 days** from final delivery (Week 13). Covers defects in delivered screens measured against the reference design. Excludes new features, scope additions, and issues originating from backend behaviour.

### Change control

Any addition to a frozen phase scope is handled as a written Change Request. Each CR is estimated in effort and separately quoted for the client's written approval before work begins. Approved CRs extend the timeline proportionally. **A screen not listed in §4 or §5 is not in scope.**

---

## 10. Accepted Scope

**All modules — 273 screens — ₹2,50,000 — 3 months (13 weeks) from kick-off**, delivered in two phases:

- **Phase 1** — ₹1,80,000 / 10 weeks / 225 screens: Foundation, UI Interface & Layouts, Authentication, **Dashboards — all 12 role dashboards**, Super Admin, CRM, HRM, Recruitment, Finance & Accounts, Administration, Settings
- **Phase 2** — ₹70,000 / 3 weeks / 48 screens: AI Center, Applications, Projects, Pages, Content Management

---

*Estimate basis: screen inventory extracted from the SmartHR reference application sidebar — 273 pages across 15 module groups. Effort derived per-screen by complexity class, scoped as customization of the React template: settings/static 2–3 h, standard list + filter + modal 4–6 h, detail/composite 6–8 h, chart dashboard 11–13 h, real-time or drag-and-drop 11–20 h. Foundation, UI Interface and layout-variant effort reflects integration and theming rather than ground-up authoring.*
