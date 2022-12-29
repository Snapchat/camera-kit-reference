package com.snap.camerakit.sample;

import android.annotation.SuppressLint;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.DiffUtil;
import androidx.recyclerview.widget.ListAdapter;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.snap.camerakit.lenses.LensesComponent;
import com.snap.camerakit.sample.dynamic.app.R;

import java.util.List;
import java.util.Set;

final class LensListAdapter extends ListAdapter<LensesComponent.Lens, LensListAdapter.ViewHolder> {

    interface Listener {

        void onClicked(LensesComponent.Lens lens);
    }

    private static final DiffUtil.ItemCallback<LensesComponent.Lens> DIFF_CALLBACK =
            new DiffUtil.ItemCallback<LensesComponent.Lens>() {
                @Override
                public boolean areItemsTheSame(
                        @NonNull LensesComponent.Lens oldItem, @NonNull LensesComponent.Lens newItem) {
                    return oldItem.getId().equals(newItem.getId());
                }

                @SuppressLint("DiffUtilEquals") // Lens model implements equals internally, safe to ignore.
                @Override
                public boolean areContentsTheSame(
                        @NonNull LensesComponent.Lens oldItem, @NonNull LensesComponent.Lens newItem) {
                    return oldItem.equals(newItem);
                }
            };

    private final Listener listener;
    private int selectedPosition = -1;

    LensListAdapter(List<LensesComponent.Lens> lenses, Listener listener) {
        super(DIFF_CALLBACK);
        submitList(lenses);
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new ViewHolder(LayoutInflater.from(parent.getContext()).inflate(R.layout.lens_item, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        holder.bind(getItem(position));
        holder.itemView.setSelected(selectedPosition == position);
    }

    final class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

        private final TextView lensIdView;
        private final ImageView lensIconView;
        private final TextView lensNameView;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            lensIdView = itemView.findViewById(R.id.lens_id);
            lensIconView = itemView.findViewById(R.id.lens_icon);
            lensNameView = itemView.findViewById(R.id.lens_name);
            itemView.setOnClickListener(this);
        }

        public void bind(LensesComponent.Lens lens) {
            lensIdView.setText(lens.getId());
            lensNameView.setText(lens.getName());
            Set<LensesComponent.Lens.Media.Image> icons = lens.getIcons();
            if (!icons.isEmpty()) {
                Glide.with(itemView).load(icons.iterator().next().getUri()).into(lensIconView);
            }
        }

        @Override
        public void onClick(View v) {
            int position = getAdapterPosition();
            if (position != RecyclerView.NO_POSITION) {
                selectedPosition = position;
                notifyDataSetChanged();
                listener.onClicked(getItem(position));
            }
        }
    }
}
