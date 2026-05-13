# Brokker Spot — Announcements API Documentation

**Base URL:** `https://api.dev.brokkerspot.com/api/v1`

**Auth Header (required on all endpoints):**
```
Authorization: Bearer <token>
Content-Type: application/json
```

---

# ══════════════════════════════════
# USER SIDE
# ══════════════════════════════════

---

## SCREEN 1 — User Bottom Nav Index 1 · AnnouncementsView
> Shows ALL OTHER USERS' active announcements as a feed. NOT the current user's own.

---

### 1.1 · Fetch Other Users' Announcements (Feed List)

**GET** `/announcements?page=1&perPage=10&search=&type=&city=`

| Query Param | Type | Required | Description |
|---|---|---|---|
| `page` | int | No | Default: 1 |
| `perPage` | int | No | Default: 10 |
| `search` | string | No | Keyword search on property name / address |
| `type` | int | No | `1` = Sell · `2` = Rent |
| `city` | string | No | Filter by city name |

> ⚠️ Must exclude the current logged-in user's own announcements.
> Only return announcements with `status = 1` (Active).

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "_id": "69fc806c1887a61a6ec4f79c",
        "listing_type": 2,
        "property_name": "Skyline Heights",
        "property_city": "Dubai",
        "property_area": "Downtown",
        "property_address": "123 Main Street, Tower A",
        "property_type": "Apartment",
        "property_size": { "sqft": 1200, "sqm": 111 },
        "bedrooms": 2,
        "bathrooms": 2,
        "price": 95000,
        "currency": "AED",
        "propertyMedia": {
          "thumbnail": "https://cdn.example.com/thumb.jpg",
          "images": ["https://cdn.example.com/img1.jpg"],
          "videos": "https://cdn.example.com/video.mp4"
        },
        "proposal_count": 4,
        "is_wishlisted": false,
        "status": 1,
        "created_at": "2025-05-11T10:00:00.000Z",
        "owner": {
          "_id": "69d207639393950cbb7c5157",
          "name": "Rachid Mansour",
          "avatar_url": "https://cdn.example.com/avatar.jpg",
          "phone": "+971501234567"
        }
      }
    ],
    "total": 100,
    "page": 1,
    "perPage": 10
  }
}
```

---

### 1.2 · Tap Card → Announcement Detail (Other User's)

**GET** `/announcements/:id`

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "69fc806c1887a61a6ec4f79c",
    "listing_type": 2,
    "is_commercial": false,
    "property_country": "UAE",
    "property_city": "Dubai",
    "property_area": "Downtown",
    "property_address": "123 Main Street, Tower A",
    "property_location": { "type": "Point", "coordinates": [55.2708, 25.2048] },
    "property_type": "Apartment",
    "property_name": "Skyline Heights",
    "property_size": { "sqft": 1200, "sqm": 111 },
    "bedrooms": 2,
    "bathrooms": 2,
    "floor": 5,
    "total_floors": 20,
    "description": "Spacious apartment with full sea view.",
    "amenities": [
      { "_id": "64abc123", "name": "Balcony" },
      { "_id": "64abc124", "name": "Shared Pool" }
    ],
    "propertyStatus": 1,
    "completion_date": null,
    "propertyMedia": {
      "images": ["https://cdn.example.com/img1.jpg", "https://cdn.example.com/img2.jpg"],
      "videos": "https://cdn.example.com/video.mp4",
      "thumbnail": "https://cdn.example.com/img1.jpg"
    },
    "price": 95000,
    "currency": "AED",
    "rentPeriod": "yearly",
    "availableDate": "2025-09-01T00:00:00.000Z",
    "brokkerage_percent": 2,
    "proposals_limit": 50,
    "proposal_count": 4,
    "is_wishlisted": false,
    "status": 1,
    "created_at": "2025-05-11T10:00:00.000Z",
    "owner": {
      "_id": "69d207639393950cbb7c5157",
      "name": "Rachid Mansour",
      "avatar_url": "https://cdn.example.com/avatar.jpg",
      "phone": "+971501234567"
    }
  }
}
```

---

### 1.3 · Wishlist Toggle (Heart icon on card / detail)

**POST** `/user/wishlist/:announcementId`

No request body. Toggles on/off — if already wishlisted removes it, otherwise adds it.

**Response:**
```json
{
  "success": true,
  "is_wishlisted": true,
  "message": "Added to wishlist"
}
```

---

### 1.4 · Start Chat with Property Owner (Call / Chat buttons on detail)

> Used when the current user wants to contact the property owner directly.

**POST** `/chat/rooms`

**Request Body:**
```json
{
  "announcement_id": "69fc806c1887a61a6ec4f79c",
  "participant_id": "69d207639393950cbb7c5157",
  "room_type": "user_to_user"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "room_id": "room_abc123",
    "announcement_id": "69fc806c1887a61a6ec4f79c",
    "participant_a": "current_user_id",
    "participant_b": "69d207639393950cbb7c5157",
    "created_at": "2025-05-11T10:00:00.000Z"
  }
}
```

---

---

## SCREEN 2 — User Account → Announcement · MyAnnouncementsTabView
> Shows the CURRENT USER'S OWN announcements. Has tabs: All / Active / Pending / Rejected / Draft.

---

### 2.1 · Fetch My Announcements (Tab Filtered)

**GET** `/user/announcements?page=1&perPage=10&status=`

| Query Param | Type | Required | Description |
|---|---|---|---|
| `page` | int | No | Default: 1 |
| `perPage` | int | No | Default: 10 |
| `status` | string | No | `active` · `pending` · `rejected` · `draft` · omit for All |

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "_id": "69fc806c1887a61a6ec4f79c",
        "listing_type": 1,
        "is_commercial": false,
        "property_name": "Skyline Heights",
        "property_city": "Dubai",
        "property_area": "Downtown",
        "property_size": { "sqft": 1200, "sqm": 111 },
        "bedrooms": 2,
        "bathrooms": 2,
        "price": 95000,
        "currency": "AED",
        "propertyMedia": {
          "thumbnail": "https://cdn.example.com/thumb.jpg",
          "images": ["https://cdn.example.com/img1.jpg"],
          "videos": "https://cdn.example.com/video.mp4"
        },
        "proposal_count": 4,
        "proposals_limit": 100,
        "status": 1,
        "created_at": "2025-05-11T10:00:00.000Z"
      }
    ],
    "total": 15,
    "page": 1,
    "perPage": 10
  }
}
```

> `status` integer mapping:
> `1` = Active · `2` = Pending · `3` = Rejected · `4` = Draft

---

### 2.2 · Tap Card → My Announcement Detail

**GET** `/user/announcements/:id`

**Response:** Same as section 1.2 but without `owner` object (it's the user's own). Adds `rejection_reason`:

```json
{
  "success": true,
  "data": {
    "_id": "69fc806c1887a61a6ec4f79c",
    "listing_type": 1,
    "is_commercial": false,
    "property_country": "UAE",
    "property_city": "Dubai",
    "property_area": "Downtown",
    "property_address": "123 Main Street, Tower A",
    "property_location": { "type": "Point", "coordinates": [55.2708, 25.2048] },
    "property_type": "Apartment",
    "property_name": "Skyline Heights",
    "property_size": { "sqft": 1200, "sqm": 111 },
    "bedrooms": 2,
    "bathrooms": 2,
    "floor": 5,
    "total_floors": 20,
    "description": "Spacious apartment with full sea view.",
    "amenities": [
      { "_id": "64abc123", "name": "Balcony" },
      { "_id": "64abc124", "name": "Shared Pool" }
    ],
    "propertyStatus": 1,
    "completion_date": null,
    "propertyMedia": {
      "images": ["https://cdn.example.com/img1.jpg"],
      "videos": "https://cdn.example.com/video.mp4",
      "thumbnail": "https://cdn.example.com/img1.jpg"
    },
    "price": 95000,
    "currency": "AED",
    "brokkerage_percent": 2,
    "rentPeriod": null,
    "availableDate": null,
    "proposals_limit": 50,
    "proposal_count": 4,
    "property_documents": {
      "titleDeed": { "fileUrl": "https://cdn.example.com/deed.pdf" },
      "passport": {
        "frontUrl": "https://cdn.example.com/passport_front.jpg",
        "backUrl": "https://cdn.example.com/passport_back.jpg"
      },
      "noc": { "fileUrl": "https://cdn.example.com/noc.pdf" }
    },
    "status": 3,
    "rejection_reason": "The title deed document is not legible. Please upload a clearer copy.",
    "created_at": "2025-05-11T10:00:00.000Z",
    "updated_at": "2025-05-12T08:00:00.000Z"
  }
}
```

> `rejection_reason` is shown in the **View Reason** dialog when `status = 3` (Rejected).

---

### 2.3 · Mark Announcement as Not Available (3-dot menu)

**PATCH** `/user/announcements/:id/not-available`

No request body.

**Response:**
```json
{
  "success": true,
  "message": "Announcement marked as not available"
}
```

---

---

### 2.4 · Active Status Bottom Bar → Proposals · AnnouncementProposalsView

---

#### 2.4.1 · Fetch Proposals for Announcement

**GET** `/user/announcements/:id/proposals`

**Response:**
```json
{
  "success": true,
  "data": {
    "proposals_limit": 100,
    "total_proposals": 4,
    "proposals": [
      {
        "_id": "proposal_id_001",
        "broker_id": "broker_user_id",
        "broker_name": "Cynthia Manda",
        "broker_avatar": "https://cdn.example.com/broker_avatar.jpg",
        "broker_rating": 4.5,
        "message": "Hi Rachid, I have a potential tenant interested in renting your property at DAMAC Sun City, Dubailand, Dubai. Here's the proposed deal:\n• Rent: 3,740,000 yearly\n• Deposit: 40,000\n• Lease Term: 12 months\n• Move-in Date: 25/09/2024",
        "created_at": "2025-05-11T09:55:00.000Z"
      }
    ]
  }
}
```

---

#### 2.4.2 · Update Proposals Limit (toggle in Proposals screen)

**PATCH** `/user/announcements/:id/proposals-limit`

**Request Body:**
```json
{
  "proposals_limit": 50
}
```

**Response:**
```json
{
  "success": true,
  "message": "Proposals limit updated",
  "data": {
    "proposals_limit": 50
  }
}
```

---

#### 2.4.3 · START CHAT (User taps START CHAT after reading a broker proposal)

**POST** `/chat/rooms`

**Request Body:**
```json
{
  "announcement_id": "69fc806c1887a61a6ec4f79c",
  "participant_id": "broker_user_id",
  "proposal_id": "proposal_id_001",
  "room_type": "user_to_broker"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "room_id": "room_xyz789",
    "announcement_id": "69fc806c1887a61a6ec4f79c",
    "user_id": "current_user_id",
    "broker_id": "broker_user_id",
    "proposal_id": "proposal_id_001",
    "created_at": "2025-05-11T10:00:00.000Z"
  }
}
```

> If a room already exists for this user + broker + announcement, return the existing room (do not create duplicate).

---

#### 2.4.4 · Load Chat Messages · AnnouncementChatView

**GET** `/chat/rooms/:roomId/messages?page=1&perPage=20`

**Response:**
```json
{
  "success": true,
  "data": {
    "room_id": "room_xyz789",
    "messages": [
      {
        "_id": "msg_001",
        "sender_id": "current_user_id",
        "sender_role": "user",
        "message": "Hi, I'm interested in the deal.",
        "created_at": "2025-05-11T10:05:00.000Z"
      },
      {
        "_id": "msg_002",
        "sender_id": "broker_user_id",
        "sender_role": "broker",
        "message": "Hi! Happy to discuss the details.",
        "created_at": "2025-05-11T10:06:00.000Z"
      }
    ],
    "total": 2,
    "page": 1,
    "perPage": 20
  }
}
```

---

#### 2.4.5 · Send Chat Message

**POST** `/chat/rooms/:roomId/messages`

**Request Body:**
```json
{
  "message": "Hello, I'm interested in this deal."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "msg_003",
    "room_id": "room_xyz789",
    "sender_id": "current_user_id",
    "sender_role": "user",
    "message": "Hello, I'm interested in this deal.",
    "created_at": "2025-05-11T10:07:00.000Z"
  }
}
```

---

---

## SCREEN 3 — Create / Edit Announcement · CreateAnnouncementView
> Accessed via the `+` button on AnnouncementsView or MyAnnouncementsTabView, or via Edit in the detail 3-dot menu.

---

### 3.1 · Get Amenities List (loads when PropertyInformationView opens)

**GET** `/amenities`

**Response:**
```json
{
  "success": true,
  "data": [
    { "_id": "64abc123", "name": "Partly Furnished" },
    { "_id": "64abc124", "name": "Balcony" },
    { "_id": "64abc125", "name": "Built in Wardrobes" },
    { "_id": "64abc126", "name": "Central A/C" },
    { "_id": "64abc127", "name": "Concierge" },
    { "_id": "64abc128", "name": "Covered Parking" },
    { "_id": "64abc129", "name": "Security" },
    { "_id": "64abc130", "name": "Shared Gym" },
    { "_id": "64abc131", "name": "Shared Pool" },
    { "_id": "64abc132", "name": "View of Water" }
  ]
}
```

> The app will display the `name` in the checkbox list but send `_id` values to the create/edit API.

---

### 3.2 · File Upload (images, video, documents)

**POST** `/files/upload`  *(multipart/form-data)*

| Field | Type | Description |
|---|---|---|
| `file` | binary | The file to upload |
| `file_type` | string | `announcements` |

**Response:**
```json
{
  "success": true,
  "data": {
    "url": "https://cdn.example.com/announcements/uuid_filename.jpg"
  }
}
```

---

### 3.3 · Create Announcement

**POST** `/user/announcements/add`

---

#### For SELL (`listing_type: 1`):

**Request Body:**
```json
{
  "listing_type": 1,
  "is_commercial": false,
  "property_country": "UAE",
  "property_city": "Dubai",
  "property_area": "Downtown",
  "property_address": "123 Main Street, Tower A",
  "property_location": {
    "type": "Point",
    "coordinates": [55.2708, 25.2048]
  },
  "property_type": "Apartment",
  "property_name": "Skyline Heights",
  "property_size": { "sqft": 1200, "sqm": 111 },
  "bedrooms": 2,
  "bathrooms": 2,
  "floor": 5,
  "total_floors": 20,
  "description": "Spacious apartment with full sea view.",
  "amenities": ["64abc123", "64abc124"],
  "propertyStatus": 1,
  "completion_date": null,
  "propertyMedia": {
    "images": [
      "https://cdn.example.com/img1.jpg",
      "https://cdn.example.com/img2.jpg"
    ],
    "videos": "https://cdn.example.com/video.mp4",
    "thumbnail": "https://cdn.example.com/img1.jpg"
  },
  "price": 950000,
  "currency": "AED",
  "brokkerage_percent": 2,
  "proposals_limit": 50,
  "property_documents": {
    "titleDeed": { "fileUrl": "https://cdn.example.com/deed.pdf" },
    "passport": {
      "frontUrl": "https://cdn.example.com/passport_front.jpg",
      "backUrl": "https://cdn.example.com/passport_back.jpg"
    },
    "noc": { "fileUrl": "https://cdn.example.com/noc.pdf" }
  },
  "status": 1
}
```

> `is_commercial`: boolean — from the Commercial Property toggle in Property Information.
> `completion_date`: ISO 8601 string — **required only when `propertyStatus = 2` (Off Plan)**. Send `null` otherwise.
> `amenities`: array of ObjectId strings from the `/amenities` API.
> `proposals_limit`: optional, send only if user sets a limit.

---

#### For RENT (`listing_type: 2`):

Same body as Sell but replace `brokkerage_percent` with:

```json
{
  "listing_type": 2,
  "rentPeriod": "yearly",
  "availableDate": "2025-09-01T00:00:00.000Z",
  ...
}
```

> `rentPeriod`: `"monthly"` or `"yearly"` (lowercase)
> `availableDate`: ISO 8601 date string

---

**Response (Create):**
```json
{
  "success": true,
  "message": "Announcement created successfully",
  "data": {
    "_id": "69fc806c1887a61a6ec4f79c",
    "status": 2,
    "created_at": "2025-05-11T10:00:00.000Z"
  }
}
```

---

### 3.4 · Edit Announcement

**PUT** `/user/announcements/edit/:id`

Same request body as Create (3.3). Send all fields — full replace.

**Response:**
```json
{
  "success": true,
  "message": "Announcement updated successfully",
  "data": {
    "_id": "69fc806c1887a61a6ec4f79c",
    "updated_at": "2025-05-12T08:00:00.000Z"
  }
}
```

---

---

# ══════════════════════════════════
# BROKER SIDE
# ══════════════════════════════════

---

## SCREEN 4 — Broker Bottom Nav Index 1 · BrokerProjectsView
> Shows ALL active user announcements that the broker can view and propose on.

---

### 4.1 · Fetch All Announcements (Broker Feed)

**GET** `/broker/announcements?page=1&perPage=10&search=&type=&city=`

| Query Param | Type | Required | Description |
|---|---|---|---|
| `page` | int | No | Default: 1 |
| `perPage` | int | No | Default: 10 |
| `search` | string | No | Keyword on property name / address |
| `type` | int | No | `1` = Sell · `2` = Rent |
| `city` | string | No | Filter by city |

> Only return announcements with `status = 1` (Active).
> Include a flag `has_proposed` so the broker knows if they already sent a proposal.

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "_id": "69fc806c1887a61a6ec4f79c",
        "listing_type": 2,
        "property_name": "Skyline Heights",
        "property_city": "Dubai",
        "property_area": "Downtown",
        "property_type": "Apartment",
        "property_size": { "sqft": 1200, "sqm": 111 },
        "bedrooms": 2,
        "bathrooms": 2,
        "price": 95000,
        "currency": "AED",
        "propertyMedia": {
          "thumbnail": "https://cdn.example.com/thumb.jpg",
          "images": ["https://cdn.example.com/img1.jpg"],
          "videos": null
        },
        "proposal_count": 4,
        "has_proposed": false,
        "status": 1,
        "created_at": "2025-05-11T10:00:00.000Z",
        "owner": {
          "_id": "69d207639393950cbb7c5157",
          "name": "Rachid Mansour",
          "avatar_url": "https://cdn.example.com/avatar.jpg"
        }
      }
    ],
    "total": 50,
    "page": 1,
    "perPage": 10
  }
}
```

---

### 4.2 · Tap Card → Broker Announcement Detail · BrokerAnnouncementDetailView

**GET** `/broker/announcements/:id`

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "69fc806c1887a61a6ec4f79c",
    "listing_type": 2,
    "is_commercial": false,
    "property_country": "UAE",
    "property_city": "Dubai",
    "property_area": "Downtown",
    "property_address": "123 Main Street, Tower A",
    "property_location": { "type": "Point", "coordinates": [55.2708, 25.2048] },
    "property_type": "Apartment",
    "property_name": "Skyline Heights",
    "property_size": { "sqft": 1200, "sqm": 111 },
    "bedrooms": 2,
    "bathrooms": 2,
    "floor": 5,
    "total_floors": 20,
    "description": "Spacious apartment with full sea view.",
    "amenities": [
      { "_id": "64abc123", "name": "Balcony" },
      { "_id": "64abc124", "name": "Shared Pool" }
    ],
    "propertyStatus": 1,
    "completion_date": null,
    "propertyMedia": {
      "images": [
        "https://cdn.example.com/img1.jpg",
        "https://cdn.example.com/img2.jpg"
      ],
      "videos": "https://cdn.example.com/video.mp4",
      "thumbnail": "https://cdn.example.com/img1.jpg"
    },
    "price": 95000,
    "currency": "AED",
    "rentPeriod": "yearly",
    "availableDate": "2025-09-01T00:00:00.000Z",
    "proposals_limit": 50,
    "proposal_count": 4,
    "has_proposed": false,
    "status": 1,
    "created_at": "2025-05-11T10:00:00.000Z",
    "owner": {
      "_id": "69d207639393950cbb7c5157",
      "name": "Rachid Mansour",
      "avatar_url": "https://cdn.example.com/avatar.jpg",
      "phone": "+971501234567"
    }
  }
}
```

---

### 4.3 · Tap "Interested" → Send Proposal · _ProposalSheet

**POST** `/broker/announcements/:id/proposal`

**Request Body:**
```json
{
  "message": "Hi Rachid, I have a potential tenant interested in renting your property at DAMAC Sun City, Dubailand, Dubai. Here's the proposed deal:\n• Rent: 3,740,000 yearly\n• Deposit: 40,000\n• Lease Term: 12 months\n• Move-in Date: 25/09/2024"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Proposal sent successfully",
  "data": {
    "_id": "proposal_id_001",
    "announcement_id": "69fc806c1887a61a6ec4f79c",
    "broker_id": "broker_user_id",
    "message": "Hi Rachid...",
    "created_at": "2025-05-11T10:00:00.000Z"
  }
}
```

---

### 4.4 · Broker Chat (after user accepts / starts chat)

> Same chat endpoints as User side.

#### Load Messages

**GET** `/chat/rooms/:roomId/messages?page=1&perPage=20`

*(Same response as section 2.5.4)*

#### Send Message

**POST** `/chat/rooms/:roomId/messages`

**Request Body:**
```json
{
  "message": "Hello, happy to proceed with the deal."
}
```

*(Same response as section 2.5.5 with `sender_role: "broker"`)*

---

---

# ══════════════════════════════════
# SHARED / REFERENCE TABLES
# ══════════════════════════════════

## `status` (Announcement status)

| Integer | String label | Description |
|---|---|---|
| `1` | `active` | Approved by admin, visible to brokers |
| `2` | `pending` | Submitted, waiting admin review |
| `3` | `rejected` | Rejected by admin, `rejection_reason` included in detail |
| `4` | `draft` | Incomplete, not yet submitted |

## `listing_type`

| Integer | Label |
|---|---|
| `1` | Sell |
| `2` | Rent |

## `propertyStatus`

| Integer | Label | Notes |
|---|---|---|
| `1` | Ready | — |
| `2` | Off Plan | `completion_date` field is required |

## Error Response Format

All errors must follow this shape:

```json
{
  "success": false,
  "message": "Human-readable error description",
  "errors": ["Optional array of field-level errors"]
}
```

## Pagination (all list endpoints)

```json
{
  "total": 100,
  "page": 1,
  "perPage": 10
}
```
