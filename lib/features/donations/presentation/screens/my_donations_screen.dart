
import 'package:flutter/material.dart';
import '../widgets/donation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/donation_provider.dart';

class MyDonationsScreen extends ConsumerStatefulWidget {
  const MyDonationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends ConsumerState<MyDonationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(donationsProvider.notifier).fetchMyDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationsProvider);
    final myDonations = state.donations;
    final isLoading = state.isLoading;
    final error = state.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Donations'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : myDonations.isEmpty
                  ? const Center(child: Text('No donations yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: myDonations.length,
                      itemBuilder: (context, index) {
                        final donation = myDonations[index];
                        return DonationCard(
                          donation: donation,
                          onTap: () {},
                        );
                      },
                    ),
    );
  }
}
