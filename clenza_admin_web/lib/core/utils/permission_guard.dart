enum ClubRole { foundingAdmin, president, secretary, treasurer, member }

class PermissionGuard {
  static bool canAddMembers(ClubRole role) =>
    role == ClubRole.secretary || role == ClubRole.foundingAdmin;

  static bool canUploadFinance(ClubRole role) =>
    role == ClubRole.treasurer;

  static bool canInitiateElection(ClubRole role) =>
    role == ClubRole.president || role == ClubRole.foundingAdmin;

  static bool canConfirmElectionResult(ClubRole role) =>
    role == ClubRole.president || role == ClubRole.foundingAdmin;

  static bool canCreateEvent(ClubRole role) =>
    role == ClubRole.president || role == ClubRole.secretary;

  static bool canSendNotification(ClubRole role) =>
    role == ClubRole.president || role == ClubRole.secretary;

  static bool canApproveTransaction(ClubRole role) =>
    role == ClubRole.president;

  static bool canUploadDocument(ClubRole role) =>
    role == ClubRole.president || role == ClubRole.secretary;
}
