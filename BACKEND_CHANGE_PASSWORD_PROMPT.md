# Backend: Change Password API Implementation

## Overview
Implementasi API endpoint untuk change password di mobile app. User dapat mengubah password dengan validasi current password.

## API Endpoint

### POST `/api/users/change-password`

**Authentication**: Required (Bearer Token)

**Request Body:**
```json
{
  "currentPassword": "oldpassword123",
  "newPassword": "newpassword456"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Password berhasil diubah"
}
```

**Error Responses:**

- **401 Unauthorized** (current password salah):
```json
{
  "success": false,
  "error": "Password saat ini tidak sesuai"
}
```

- **400 Bad Request** (validation error):
```json
{
  "success": false,
  "error": "Password baru harus minimal 8 karakter"
}
```

- **401 Unauthorized** (no token):
```json
{
  "success": false,
  "error": "Unauthorized"
}
```

## Implementation Guide

### 1. Create Route Handler

File: `app/api/users/change-password/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import bcrypt from 'bcryptjs';
import { verifyToken } from '@/lib/auth';

export async function POST(request: NextRequest) {
  try {
    // 1. Verify authentication
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    if (!token) {
      return NextResponse.json(
        { success: false, error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const decoded = verifyToken(token);
    if (!decoded?.userId) {
      return NextResponse.json(
        { success: false, error: 'Invalid token' },
        { status: 401 }
      );
    }

    // 2. Parse request body
    const { currentPassword, newPassword } = await request.json();

    // 3. Validate input
    if (!currentPassword || !newPassword) {
      return NextResponse.json(
        { success: false, error: 'Current password dan password baru wajib diisi' },
        { status: 400 }
      );
    }

    if (newPassword.length < 8) {
      return NextResponse.json(
        { success: false, error: 'Password baru harus minimal 8 karakter' },
        { status: 400 }
      );
    }

    // 4. Get user from database
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, password: true, email: true }
    });

    if (!user) {
      return NextResponse.json(
        { success: false, error: 'User tidak ditemukan' },
        { status: 404 }
      );
    }

    // 5. Check if user has password (not Google login)
    if (!user.password) {
      return NextResponse.json(
        { success: false, error: 'Akun ini menggunakan login Google dan tidak memiliki password' },
        { status: 400 }
      );
    }

    // 6. Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isPasswordValid) {
      return NextResponse.json(
        { success: false, error: 'Password saat ini tidak sesuai' },
        { status: 401 }
      );
    }

    // 7. Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // 8. Update password in database
    await prisma.user.update({
      where: { id: user.id },
      data: { password: hashedPassword }
    });

    console.log(`[ChangePassword] User ${user.email} changed password successfully`);

    // 9. Return success
    return NextResponse.json({
      success: true,
      message: 'Password berhasil diubah'
    });

  } catch (error: any) {
    console.error('[ChangePassword] Error:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
```

### 2. Security Considerations

- ✅ **Rate Limiting**: Consider adding rate limiting to prevent brute force attacks
- ✅ **Password Validation**: Minimal 8 characters (enforced on frontend, validated on backend)
- ✅ **Bcrypt Hashing**: Use bcrypt with 10 rounds for password hashing
- ✅ **Token Verification**: Verify JWT token untuk authentication
- ✅ **Current Password Check**: Wajib verify current password sebelum allow change
- ✅ **Google Login**: Return error jika user login via Google (no password)

### 3. Testing Checklist

Test the endpoint with these scenarios:

- ✅ **Valid Change**: Current password benar, new password valid → Success
- ✅ **Wrong Current Password**: Current password salah → 401 error
- ✅ **Weak New Password**: Password < 8 chars → 400 error
- ✅ **No Token**: Request tanpa Bearer token → 401 error
- ✅ **Invalid Token**: Token expired/invalid → 401 error
- ✅ **Google User**: User login via Google → 400 error dengan proper message
- ✅ **Missing Fields**: currentPassword atau newPassword kosong → 400 error

### 4. Database Schema

Existing schema (no changes needed):

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  password  String?  // Nullable untuk Google login users
  name      String
  // ... other fields
}
```

## Mobile App Integration

Mobile app sudah implement:
- ✅ Security screen dengan menu
- ✅ Change password screen dengan:
  - Real-time password strength indicator (Weak/Medium/Strong)
  - Requirements checklist (min 8 chars, uppercase, lowercase, number)
  - Show/hide password toggle
  - Password match validation
  - Smooth animations
- ✅ API call ke POST `/api/users/change-password`
- ✅ Success dialog dan navigation
- ✅ Error handling

## Notes

- Password change tidak logout user yang sedang aktif
- Jika perlu logout all devices, implement separate "logout all sessions" feature
- Consider sending email notification setelah password berhasil diubah (security alert)
- Log password change events untuk audit trail

## Priority

🔴 **HIGH PRIORITY** - User butuh functionality ini untuk security account
