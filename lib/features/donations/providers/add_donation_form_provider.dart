import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Form State ─────────────────────────────────────────
class AddDonationFormState {
  final String  title;
  final String  category;
  final String  pickupType;
  final String  quantity;
  final String  description;
  final String  meetingZone;
  final String  expiresAt;
  final String? imageBase64;
  final bool    checklistConfirmed;

  const AddDonationFormState({
    this.title             = '',
    this.category          = 'FRESH',
    this.pickupType        = 'PICKUP',
    this.quantity          = '',
    this.description       = '',
    this.meetingZone       = '',
    this.expiresAt         = '',
    this.imageBase64,
    this.checklistConfirmed = false,
  });

  bool get isValid =>
      title.isNotEmpty &&
      quantity.isNotEmpty &&
      expiresAt.isNotEmpty;

  AddDonationFormState copyWith({
    String?  title,
    String?  category,
    String?  pickupType,
    String?  quantity,
    String?  description,
    String?  meetingZone,
    String?  expiresAt,
    String?  imageBase64,
    bool?    checklistConfirmed,
  }) {
    return AddDonationFormState(
      title:              title             ?? this.title,
      category:           category          ?? this.category,
      pickupType:         pickupType        ?? this.pickupType,
      quantity:           quantity          ?? this.quantity,
      description:        description       ?? this.description,
      meetingZone:        meetingZone       ?? this.meetingZone,
      expiresAt:          expiresAt         ?? this.expiresAt,
      imageBase64:        imageBase64       ?? this.imageBase64,
      checklistConfirmed: checklistConfirmed ?? this.checklistConfirmed,
    );
  }

  // ── Reset form ─────────────────────────────────
  AddDonationFormState reset() => const AddDonationFormState();
}

// ── Form Notifier ──────────────────────────────────────
class AddDonationFormNotifier extends StateNotifier<AddDonationFormState> {
  AddDonationFormNotifier() : super(const AddDonationFormState());

  void setTitle(String v)             => state = state.copyWith(title: v);
  void setCategory(String v)          => state = state.copyWith(category: v);
  void setPickupType(String v)        => state = state.copyWith(pickupType: v);
  void setQuantity(String v)          => state = state.copyWith(quantity: v);
  void setDescription(String v)       => state = state.copyWith(description: v);
  void setMeetingZone(String v)       => state = state.copyWith(meetingZone: v);
  void setExpiresAt(String v)         => state = state.copyWith(expiresAt: v);
  void setImageBase64(String? v)      => state = state.copyWith(imageBase64: v);
  void setChecklist(bool v)           => state = state.copyWith(checklistConfirmed: v);
  void reset()                        => state = state.reset();
}

// ── Provider — kept alive so form survives navigation ──
final addDonationFormProvider =
    StateNotifierProvider<AddDonationFormNotifier, AddDonationFormState>((ref) {
  return AddDonationFormNotifier();
});