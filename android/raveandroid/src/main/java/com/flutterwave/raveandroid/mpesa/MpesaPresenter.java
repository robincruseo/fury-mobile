package com.flutterwave.raveandroid.mpesa;

import android.content.Context;
import android.util.Log;

import com.flutterwave.raveandroid.FeeCheckRequestBody;
import com.flutterwave.raveandroid.Payload;
import com.flutterwave.raveandroid.RaveConstants;
import com.flutterwave.raveandroid.Utils;
import com.flutterwave.raveandroid.card.ChargeRequestBody;
import com.flutterwave.raveandroid.data.Callbacks;
import com.flutterwave.raveandroid.data.NetworkRequestImpl;
import com.flutterwave.raveandroid.data.RequeryRequestBody;
import com.flutterwave.raveandroid.data.RequeryRequestBodyv2;
import com.flutterwave.raveandroid.responses.ChargeResponse;
import com.flutterwave.raveandroid.responses.FeeCheckResponse;
import com.flutterwave.raveandroid.responses.RequeryResponse;
import com.flutterwave.raveandroid.responses.RequeryResponsev2;

import static com.flutterwave.raveandroid.RaveConstants.AVS_VBVSECURECODE;

/**
 * Created by hfetuga on 27/06/2018.
 */

public class MpesaPresenter implements MpesaContract.UserActionsListener {
    private Context context;
    private MpesaContract.View mView;

    public MpesaPresenter(Context context, MpesaContract.View mView) {
        this.context = context;
        this.mView = mView;
    }

    @Override
    public void fetchFee(final Payload payload) {
        FeeCheckRequestBody body = new FeeCheckRequestBody();
        body.setAmount(payload.getAmount());
        body.setCurrency(payload.getCurrency());
        body.setPtype("3");
        body.setPBFPubKey(payload.getPBFPubKey());

        mView.showProgressIndicator(true);

        new NetworkRequestImpl().getFee(body, new Callbacks.OnGetFeeRequestComplete() {
            @Override
            public void onSuccess(FeeCheckResponse response) {
                mView.showProgressIndicator(false);

                try {
                    mView.displayFee(response.getData().getCharge_amount(), payload);
                }
                catch (Exception e) {
                    e.printStackTrace();
                    mView.showFetchFeeFailed("An error occurred while retrieving transaction fee");
                }
            }

            @Override
            public void onError(String message) {
                mView.showProgressIndicator(false);
                Log.e(RaveConstants.RAVEPAY, message);
                mView.showFetchFeeFailed("An error occurred while retrieving transaction fee");
            }
        });
    }

    @Override
    public void chargeMpesa(Payload payload, final String secretKey) {
        String cardRequestBodyAsString = Utils.convertChargeRequestPayloadToJson(payload);
        String encryptedCardRequestBody = Utils.getEncryptedData(cardRequestBodyAsString, secretKey).trim().replaceAll("\\n", "");

//        Log.d("encrypted", encryptedCardRequestBody);

        ChargeRequestBody body = new ChargeRequestBody();
        body.setAlg("3DES-24");
        body.setPBFPubKey(payload.getPBFPubKey());
        body.setClient(encryptedCardRequestBody);

        mView.showProgressIndicator(true);

        new NetworkRequestImpl().chargeCard(body, new Callbacks.OnChargeRequestComplete() {
            @Override
            public void onSuccess(ChargeResponse response, String responseAsJSONString) {

                mView.showProgressIndicator(false);

                if (response.getData() != null) {
                    Log.d("resp", responseAsJSONString);

                    String flwRef = response.getData().getFlwRef();
                    String txRef = response.getData().getTx_ref();
                    requeryTxv2(flwRef, txRef, secretKey);
                }
                else {
                    mView.onPaymentError("No response data was returned");
                }

            }

            @Override
            public void onError(String message, String responseAsJSONString) {
                mView.showProgressIndicator(false);
                mView.onPaymentError(message);
            }
        });
    }

    @Override
    public void requeryTxv2(final String flwRef, final String txRef, final String secretKey) {

        RequeryRequestBodyv2 body = new RequeryRequestBodyv2();
        body.setTxref(txRef);
        body.setSECKEY(secretKey);

        mView.showPollingIndicator(true);

        new NetworkRequestImpl().requeryTxv2(body, new Callbacks.OnRequeryRequestv2Complete() {
            @Override
            public void onSuccess(RequeryResponsev2 response, String responseAsJSONString) {
                if (response.getData() == null) {
                    mView.onPaymentFailed(response.getStatus(), responseAsJSONString);
                }
                else if (response.getData().getChargecode().equals("02")){
                    mView.onPollingRoundComplete(flwRef, txRef, secretKey);
                }
                else if (response.getData().getChargecode().equals("00")) {
                    requeryTx(flwRef, secretKey);
                }
                else {
                    mView.showPollingIndicator(false);
                    mView.onPaymentFailed(response.getData().getStatus(), responseAsJSONString);
                }
            }

            @Override
            public void onError(String message, String responseAsJSONString) {
                mView.onPaymentFailed(message, responseAsJSONString);
            }
        });

    }

    private void requeryTx(final String flwRef, final String SECKEY) {

        RequeryRequestBody body = new RequeryRequestBody();
        body.setFlw_ref(flwRef);
        body.setSECKEY(SECKEY);

        mView.showPollingIndicator(false);
        mView.showProgressIndicator(true);

        new NetworkRequestImpl().requeryTx(body, new Callbacks.OnRequeryRequestComplete() {
            @Override
            public void onSuccess(RequeryResponse response, String responseAsJSONString) {
                mView.showProgressIndicator(false);
                mView.onPaymentSuccessful(response.getData().getStatus(), flwRef, responseAsJSONString);

            }

            @Override
            public void onError(String message, String responseAsJSONString) {
                mView.showProgressIndicator(false);
                mView.onPaymentSuccessful(message, flwRef, responseAsJSONString);
            }
        });
    }
}
