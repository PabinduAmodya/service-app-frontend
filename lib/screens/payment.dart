import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class PaymentPage extends StatefulWidget {
  final String userToken;
  final String requestId;
  final String workerName;
  final String requestTitle;

  const PaymentPage({
    Key? key,
    required this.userToken,
    required this.requestId,
    required this.workerName,
    required this.requestTitle,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        var response = await Dio().post(
          'http://10.0.2.2:5000/api/payments/${widget.requestId}',
          data: {
            'amount': double.parse(_amountController.text),
            'cardDetails': {
              'cardNumber': _cardNumberController.text,
              'expiryDate': _expiryDateController.text,
              'cvv': _cvvController.text,
              'cardholderName': _nameController.text,
            }
          },
          options: Options(headers: {'Authorization': 'Bearer ${widget.userToken}'}),
        );

        setState(() {
          _isProcessing = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Payment Successful'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your payment to ${widget.workerName} has been processed successfully!',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.pop(context); // Go back to work requests page
                    },
                  ),
                ],
              );
            },
          );
        } else {
          // Show error dialog
          showErrorDialog(response.data['error'] ?? 'Payment failed. Please try again.');
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        showErrorDialog('Error processing payment: ${e.toString()}');
      }
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payment Failed'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment summary section
                Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Service:'),
                            Flexible(
                              child: Text(
                                widget.requestTitle,
                                style: TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Worker:'),
                            Text(
                              widget.workerName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Payment amount field
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    hintText: 'Enter payment amount',
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                
                // Card information section
                Text(
                  'Card Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                // Card number field
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                    hintText: 'Card Number',
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card number';
                    }
                    // Remove spaces for validation
                    String cardNumber = value.replaceAll(' ', '');
                    if (cardNumber.length < 16) {
                      return 'Card number must be 16 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // Expiry date and CVV row
                Row(
                  children: [
                    // Expiry date field
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.date_range),
                          border: OutlineInputBorder(),
                          hintText: 'MM/YY',
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter expiry date';
                          }
                          if (value.length < 5) {
                            return 'Invalid format';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // CVV field
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.security),
                          border: OutlineInputBorder(),
                          hintText: 'CVV',
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter CVV';
                          }
                          if (value.length < 3) {
                            return 'CVV must be 3 digits';
                          }
                          return null;
                        },
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Cardholder name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    hintText: 'Cardholder Name',
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter cardholder name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                
                // Pay Now button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: const Color.fromARGB(255, 6, 6, 6),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isProcessing
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('PAY NOW'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom formatter for credit card number
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    String text = newValue.text.replaceAll(' ', '');
    String newText = '';
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        newText += ' ';
      }
      newText += text[i];
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// Custom formatter for expiry date
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    String newText = text;
    if (text.length == 2 && oldValue.text.length == 1) {
      newText = '$text/';
    }
    
    // Add slash after month if user types more than 2 digits
    if (text.length > 2 && !text.contains('/')) {
      newText = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}