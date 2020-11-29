class Deposit {
  bool capitalization;
  String name;
  String currency;
  double yearlyPercents;
  double amount;
  double percentsCumm = 0;
  int duration = 0;
  String type;
  int months;

  Deposit(this.name, this.currency, this.amount, this.yearlyPercents,
      this.capitalization);

  // void addAmount(double additionalAmount) {
  //   throw new DepositException(
  //       "This type of deposit does not support adding money!");
  // }
  //
  // void removeAmount(double retrievalAmount) {
  //   throw new DepositException(
  //       "This type of deposit does not support money retrieval!");
  // }

  void waitMonths(int months) {
    for (int i = 0; i < months; i++) this.waitMonth();
  }

  void waitMonth() {
    this.duration += 1;
    if (this.capitalization)
      this.percentsCumm +=
          (this.amount + this.percentsCumm) * this.yearlyPercents / 12 / 100;
    else
      this.percentsCumm += this.amount * this.yearlyPercents / 12 / 100;
  }

  Deposit.fromJson(Map<String, dynamic> json)
      : capitalization = json['capitalization'],
        name = json['name'],
        currency = json['currency'],
        yearlyPercents = json['yearlyPercents'],
        amount = json['amount'],
        percentsCumm = json['percentsCumm'],
        duration = json['duration'],
        type = json['type'],
        months = json['months'];

  Map<String, dynamic> toJson() => {
        'capitalization': capitalization,
        'name': name,
        'currency': currency,
        'yearlyPercents': yearlyPercents,
        'amount': amount,
        'percentsCumm': percentsCumm,
        'duration': duration,
        'type': type,
        'months': months
      };
}

class TermDeposit extends Deposit {
  int months;

  TermDeposit(String name, String currency, double amount,
      double yearlyPercents, bool capitalization, int months)
      : super(name, currency, amount, yearlyPercents, capitalization) {
    this.months = months;
  }
  @override
  void waitMonth() {
    super.waitMonth();
    if (this.duration % this.months == 0) {
      this.amount += this.percentsCumm;
      this.percentsCumm = 0;
    }
  }

  double cancel() {
    double temp = this.amount;
    this.amount = 0;
    return temp;
  }
}

class AccumulativeTermDeposit extends TermDeposit {
  AccumulativeTermDeposit(String name, String currency, double amount,
      double yearlyPercents, bool capitalization, int months)
      : super(name, currency, amount, yearlyPercents, capitalization, months) {
    this.type = "Accumulative Term Deposit";
  }

  void addAmount(double additionalAmount) {
    this.amount += additionalAmount;
  }
}

class SavingTermDeposit extends TermDeposit {
  SavingTermDeposit(String name, String currency, double amount,
      double yearlyPercents, bool capitalization, int months)
      : super(name, currency, amount, yearlyPercents, capitalization, months) {
    this.type = "Saving Term Deposit";
  }
}

class ExpensesTermDeposit extends TermDeposit {
  ExpensesTermDeposit(String name, String currency, double amount,
      double yearlyPercents, bool capitalization, int months)
      : super(name, currency, amount, yearlyPercents, capitalization, months) {
    this.type = "Expenses Term Deposit";
  }

  void removeAmount(double retrievalAmount) {
    this.amount -= retrievalAmount;
    if (this.amount < 0){
      this.amount = 0;
    }
  }

  void addAmount(double additionalAmount) {
    this.amount += additionalAmount;
  }
}

class DemandDeposit extends Deposit {
  DemandDeposit(String name, String currency, double amount,
      double yearlyPercents, bool capitalization)
      : super(name, currency, amount, yearlyPercents, capitalization) {
    this.type = "Demand Deposit";
  }

  double cancel() {
    double temp = this.amount + this.percentsCumm;
    this.amount = 0;
    return temp;
  }
}
